import mongoose from 'mongoose';
import bcrypt from 'bcryptjs';

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/easyshop';

async function seedDemoUser() {
  await mongoose.connect(MONGODB_URI);
  const users = mongoose.connection.collection('users');
  const password = await bcrypt.hash('test1234', 10);

  await users.updateOne(
    { email: 'demo@gmail.com' },
    {
      $set: {
        name: 'demo',
        email: 'demo@gmail.com',
        password,
        role: 'user',
        updatedAt: new Date(),
      },
      $setOnInsert: {
        createdAt: new Date(),
      },
    },
    { upsert: true }
  );

  console.log('Demo user ready: demo@gmail.com / test1234');
  await mongoose.disconnect();
}

seedDemoUser().catch((error) => {
  console.error(error);
  process.exit(1);
});
