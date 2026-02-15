import { defineSchema, defineTable } from "convex/server";
import { v } from "convex/values";

export default defineSchema({
    // Device profiles — stores user preferences per device
    deviceProfiles: defineTable({
        deviceId: v.string(),
        vibes: v.array(v.string()),
        language: v.string(),
        reminderTimes: v.array(v.string()),
        aiProvider: v.optional(v.string()),
        dailyRoastCount: v.number(),
        lastRoastDate: v.string(),
        createdAt: v.number(),
        updatedAt: v.number(),
    })
        .index("by_device_id", ["deviceId"])
        .index("by_created", ["createdAt"]),

    // Admin configuration — key-value store for runtime config
    adminConfig: defineTable({
        key: v.string(),
        value: v.string(),
        updatedAt: v.number(),
    }).index("by_key", ["key"]),

    // Admin users — email/password auth for admin panel
    adminUsers: defineTable({
        email: v.string(),
        passwordHash: v.string(),
        salt: v.string(),
        createdAt: v.number(),
    }).index("by_email", ["email"]),
});
