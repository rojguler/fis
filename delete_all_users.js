const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();
const auth = admin.auth();

async function deleteCollection(collectionPath, batchSize) {
  const collectionRef = db.collection(collectionPath);
  const query = collectionRef.orderBy('__name__').limit(batchSize);

  return new Promise((resolve, reject) => {
    deleteQueryBatch(db, query, resolve).catch(reject);
  });
}

async function deleteQueryBatch(db, query, resolve) {
  const snapshot = await query.get();

  const batchSize = snapshot.size;
  if (batchSize === 0) {
    // When there are no documents left, we are done
    resolve();
    return;
  }

  const batch = db.batch();
  snapshot.docs.forEach((doc) => {
    batch.delete(doc.ref);
  });
  await batch.commit();

  process.nextTick(() => {
    deleteQueryBatch(db, query, resolve);
  });
}

async function deleteAllAuthUsers() {
  let nextPageToken;
  let hasMoreUsers = true;
  while (hasMoreUsers) {
    const listUsersResult = await auth.listUsers(1000, nextPageToken);
    const uids = listUsersResult.users.map((userRecord) => userRecord.uid);
    if (uids.length > 0) {
      await auth.deleteUsers(uids);
      console.log(`Deleted ${uids.length} users from Auth.`);
    } else {
        console.log("No users found in Auth to delete.");
    }
    
    if (listUsersResult.pageToken) {
      nextPageToken = listUsersResult.pageToken;
    } else {
      hasMoreUsers = false;
    }
  }
}

async function main() {
    console.log("Starting deletion process...");
    
    try {
        console.log("Deleting Auth Users...");
        await deleteAllAuthUsers();
        console.log("Auth users deleted.");

        console.log("Deleting 'users' collection in Firestore...");
        await deleteCollection('users', 500);
        console.log("'users' collection deleted.");

        console.log("Deleting 'admins' collection in Firestore...");
        await deleteCollection('admins', 500);
        console.log("'admins' collection deleted.");

        console.log("All done.");
        process.exit(0);
    } catch (e) {
        console.error("Error during deletion:", e);
        process.exit(1);
    }
}

main();
