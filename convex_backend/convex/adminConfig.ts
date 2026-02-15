import { mutation, query } from "./_generated/server";
import { v } from "convex/values";

/**
 * Set multiple configuration values (admin use).
 */
export const batchSetConfigs = mutation({
    args: {
        configs: v.array(v.object({ key: v.string(), value: v.string() })),
    },
    handler: async (ctx, args) => {
        // Validate key format
        const validKeys = [
            "groq_api_key",
            "cerebras_api_key",
            "groq_model",
            "cerebras_model",
            "primary_ai_provider",
            "admin_pin",
            "app_enabled",
            "max_daily_roasts",
            "max_reminder_times",
        ];

        const now = Date.now();
        const results = [];

        for (const entry of args.configs) {
            if (!validKeys.includes(entry.key)) {
                throw new Error(`Invalid config key: ${entry.key}`);
            }

            const existing = await ctx.db
                .query("adminConfig")
                .withIndex("by_key", (q) => q.eq("key", entry.key))
                .unique();

            if (existing) {
                await ctx.db.patch(existing._id, {
                    value: entry.value,
                    updatedAt: now,
                });
                results.push({ id: existing._id, key: entry.key, action: "updated" });
            } else {
                const id = await ctx.db.insert("adminConfig", {
                    key: entry.key,
                    value: entry.value,
                    updatedAt: now,
                });
                results.push({ id, key: entry.key, action: "created" });
            }
        }
        return results;
    },
});

/**
 * Get a single config value by key.
 */
export const getConfig = query({
    args: {
        key: v.string(),
    },
    handler: async (ctx, args) => {
        const config = await ctx.db
            .query("adminConfig")
            .withIndex("by_key", (q) => q.eq("key", args.key))
            .unique();
        return config;
    },
});

/**
 * Get all config values in a single object.
 */
export const getAllConfigs = query({
    args: {},
    handler: async (ctx) => {
        const configs = await ctx.db.query("adminConfig").collect();
        const result: Record<string, any> = {};
        for (const c of configs) {
            result[c.key] = c.value;
        }
        return result;
    },
});

/**
 * List all config entries (admin dashboard).
 */
export const listConfigs = query({
    args: {},
    handler: async (ctx) => {
        return await ctx.db.query("adminConfig").collect();
    },
});
