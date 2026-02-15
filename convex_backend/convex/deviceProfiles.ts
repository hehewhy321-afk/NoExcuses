import { mutation, query } from "./_generated/server";
import { v } from "convex/values";

/**
 * Save or update a device profile.
 * Upserts based on deviceId — idempotent.
 */
export const saveProfile = mutation({
    args: {
        deviceId: v.string(),
        vibes: v.array(v.string()),
        language: v.string(),
        reminderTimes: v.array(v.string()),
        aiProvider: v.optional(v.string()),
    },
    handler: async (ctx, args) => {
        // Validate deviceId format (UUID v4)
        const uuidRegex =
            /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
        if (!uuidRegex.test(args.deviceId)) {
            throw new Error("Invalid device ID format");
        }

        // Validate vibes (max 10, non-empty strings)
        if (args.vibes.length === 0 || args.vibes.length > 10) {
            throw new Error("Vibes must contain 1-10 items");
        }
        for (const vibe of args.vibes) {
            if (vibe.trim().length === 0 || vibe.length > 50) {
                throw new Error("Each vibe must be 1-50 characters");
            }
        }

        // Validate language
        if (!["English", "Nepali"].includes(args.language)) {
            throw new Error("Language must be English or Nepali");
        }

        // Validate reminder times (1-3 times in HH:mm format)
        if (args.reminderTimes.length === 0 || args.reminderTimes.length > 3) {
            throw new Error("Must have 1-3 reminder times");
        }
        const timeRegex = /^([01]\d|2[0-3]):[0-5]\d$/;
        for (const time of args.reminderTimes) {
            if (!timeRegex.test(time)) {
                throw new Error("Reminder times must be in HH:mm format");
            }
        }

        const now = Date.now();

        // Check if profile already exists
        const existing = await ctx.db
            .query("deviceProfiles")
            .withIndex("by_device_id", (q) => q.eq("deviceId", args.deviceId))
            .unique();

        if (existing) {
            // Update existing profile
            await ctx.db.patch(existing._id, {
                vibes: args.vibes,
                language: args.language,
                reminderTimes: args.reminderTimes,
                aiProvider: args.aiProvider,
                updatedAt: now,
            });
            return { id: existing._id, action: "updated" };
        } else {
            // Create new profile
            const id = await ctx.db.insert("deviceProfiles", {
                deviceId: args.deviceId,
                vibes: args.vibes,
                language: args.language,
                reminderTimes: args.reminderTimes,
                aiProvider: args.aiProvider,
                dailyRoastCount: 0,
                lastRoastDate: "",
                createdAt: now,
                updatedAt: now,
            });
            return { id, action: "created" };
        }
    },
});

/**
 * Get a device profile by device ID.
 */
export const getProfile = query({
    args: {
        deviceId: v.string(),
    },
    handler: async (ctx, args) => {
        const profile = await ctx.db
            .query("deviceProfiles")
            .withIndex("by_device_id", (q) => q.eq("deviceId", args.deviceId))
            .unique();
        return profile;
    },
});

/**
 * Get total device count (admin stats).
 */
export const getStats = query({
    args: {},
    handler: async (ctx) => {
        const profiles = await ctx.db.query("deviceProfiles").collect();
        return {
            totalDevices: profiles.length,
            recentDevices: profiles.filter(
                (p) => p.createdAt > Date.now() - 7 * 24 * 60 * 60 * 1000
            ).length,
        };
    },
});

/**
 * Increment daily roast count for rate limiting.
 */
export const incrementRoastCount = mutation({
    args: {
        deviceId: v.string(),
    },
    handler: async (ctx, args) => {
        const profile = await ctx.db
            .query("deviceProfiles")
            .withIndex("by_device_id", (q) => q.eq("deviceId", args.deviceId))
            .unique();

        if (!profile) {
            throw new Error("Device profile not found");
        }

        const today = new Date().toISOString().split("T")[0];

        if (profile.lastRoastDate === today) {
            if (profile.dailyRoastCount >= 3) {
                throw new Error("Daily roast limit reached (max 3)");
            }
            await ctx.db.patch(profile._id, {
                dailyRoastCount: profile.dailyRoastCount + 1,
                updatedAt: Date.now(),
            });
        } else {
            // New day, reset count
            await ctx.db.patch(profile._id, {
                dailyRoastCount: 1,
                lastRoastDate: today,
                updatedAt: Date.now(),
            });
        }
    },
});
