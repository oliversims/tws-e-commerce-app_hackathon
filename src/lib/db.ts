import mongoose from 'mongoose';

interface MongooseCache {
  conn: typeof mongoose | null;
  promise: Promise<typeof mongoose> | null;
}

declare global {
  var mongoose: MongooseCache | undefined;
}

/**
 * Fail closed rather than silently defaulting to localhost: a missing
 * MONGODB_URI in a deployed environment should be a loud startup failure, not a
 * connection attempt against a database that isn't there.
 */
function getMongoUri(): string {
  const uri = process.env.MONGODB_URI;

  if (!uri) {
    throw new Error('Please define the MONGODB_URI environment variable inside .env');
  }

  return uri;
}

let cached: MongooseCache = (global.mongoose as MongooseCache) || {
  conn: null,
  promise: null,
};

if (!global.mongoose) {
  global.mongoose = cached;
}

async function dbConnect() {
  if (cached.conn) {
    return cached.conn;
  }

  if (!cached.promise) {
    const opts = {
      bufferCommands: false,
    };

    // NOTE on operator injection: mongoose's `sanitizeFilter` is deliberately
    // NOT enabled here.
    //
    // It is not a valid connect() option (passing it there is silently
    // ignored), and the documented global -- mongoose.set('sanitizeFilter') --
    // wraps ANY nested object with a `$` key in `$eq`, which would break the
    // deliberate `$in` / `$gte` / `$lte` / `$or` filters in
    // src/lib/queries/products.ts and src/lib/queries/populate.ts.
    //
    // Injection is prevented at the edges instead:
    //   - request bodies are parsed through Zod (src/lib/validation/schemas.ts)
    //     before any value reaches a filter;
    //   - query-string and path params arrive from Next.js as `string`, so they
    //     cannot carry an operator object in the first place.
    cached.promise = mongoose.connect(getMongoUri(), opts).then((mongoose) => {
      return mongoose;
    });
  }

  try {
    cached.conn = await cached.promise;
  } catch (e) {
    cached.promise = null;
    throw e;
  }

  return cached.conn;
}

export default dbConnect;
