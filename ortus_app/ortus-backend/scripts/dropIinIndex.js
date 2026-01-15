require("dotenv").config();
const mongoose = require("mongoose");

const dropIinIndex = async () => {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log("✅ MongoDB connected");

    const collection = mongoose.connection.collection("users");
    const indexes = await collection.indexes();
    const iinIndex = indexes.find(
      (index) => index.name === "iin_1" || index.key?.iin === 1
    );

    if (iinIndex) {
      await collection.dropIndex(iinIndex.name);
      console.log(`✅ Dropped index: ${iinIndex.name}`);
    } else {
      console.log("ℹ️ Index iin_1 not found, nothing to drop");
    }

    const result = await collection.updateMany(
      { iin: { $exists: true } },
      { $unset: { iin: "" } }
    );

    console.log(
      `✅ Removed iin field from ${result.modifiedCount} document(s)`
    );
  } catch (error) {
    console.error("❌ Failed to drop iin index:", error.message);
    process.exit(1);
  } finally {
    await mongoose.disconnect();
  }
};

dropIinIndex();
