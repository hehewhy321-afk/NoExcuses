import { mutation, query } from "./_generated/server";
import { v } from "convex/values";

/**
 * Simple SHA-256 hash using Web Crypto API (available in Convex runtime).
 */
async function hashPassword(password: string, salt: string): Promise<string> {
    const encoder = new TextEncoder();
    const data = encoder.encode(password + salt);
    const hashBuffer = await crypto.subtle.digest("SHA-256", data);
    const hashArray = Array.from(new Uint8Array(hashBuffer));
    return hashArray.map((b) => b.toString(16).padStart(2, "0")).join("");
}

/**
 * Generate a random salt.
 */
function generateSalt(): string {
    const array = new Uint8Array(16);
    crypto.getRandomValues(array);
    return Array.from(array)
        .map((b) => b.toString(16).padStart(2, "0"))
        .join("");
}

/**
 * Admin login — validates email + password against stored hash.
 * Returns { success: true } or { success: false, error: string }.
 */
export const login = mutation({
    args: {
        email: v.string(),
        password: v.string(),
    },
    handler: async (ctx, args) => {
        const email = args.email.toLowerCase().trim();

        const user = await ctx.db
            .query("adminUsers")
            .withIndex("by_email", (q) => q.eq("email", email))
            .unique();

        if (!user) {
            return { success: false, error: "Invalid credentials" };
        }

        const hash = await hashPassword(args.password, user.salt);

        if (hash !== user.passwordHash) {
            return { success: false, error: "Invalid credentials" };
        }

        return { success: true, email: user.email };
    },
});

/**
 * Create a new admin user.
 * Can be called from Convex dashboard or by an existing admin.
 */
export const createAdmin = mutation({
    args: {
        email: v.string(),
        password: v.string(),
    },
    handler: async (ctx, args) => {
        const email = args.email.toLowerCase().trim();

        if (!email.includes("@")) {
            throw new Error("Invalid email format");
        }
        if (args.password.length < 6) {
            throw new Error("Password must be at least 6 characters");
        }

        // Check if email already exists
        const existing = await ctx.db
            .query("adminUsers")
            .withIndex("by_email", (q) => q.eq("email", email))
            .unique();

        if (existing) {
            throw new Error("Admin with this email already exists");
        }

        const salt = generateSalt();
        const passwordHash = await hashPassword(args.password, salt);

        const id = await ctx.db.insert("adminUsers", {
            email,
            passwordHash,
            salt,
            createdAt: Date.now(),
        });

        return { id, email, action: "created" };
    },
});

/**
 * Check if any admin users exist (for first-time setup).
 */
export const hasAdmins = query({
    args: {},
    handler: async (ctx) => {
        const first = await ctx.db.query("adminUsers").first();
        return { hasAdmins: first !== null };
    },
});
