const csv = require('csv-parse');
const fs = require('fs');
const { Firestore } = require('@google-cloud/firestore');
const { Logging } = require('@google-cloud/logging'); // Add this line

// Add constant variables for logging
const logName = "pet-theory-logs-importTestData";

// Creates a Logging client
const logging = new Logging();
const log = logging.log(logName);

const resource = {
  type: "global",
};

async function writeToDatabase(records) {
  records.forEach((record, i) => {
    console.log(`ID: ${record.id} Email: ${record.email} Name: ${record.name} Phone: ${record.phone}`);
  });
  return;
}

async function writeToFirestore(records) {
  const db = new Firestore({
    // projectId: projectId
  });
  const batch = db.batch();

  records.forEach((record) => {
    console.log(`Write: ${record}`);
    const docRef = db.collection('customers').doc(record.email);
    batch.set(docRef, record, { merge: true });
  });

  try {
    await batch.commit();
    console.log('Batch executed');
    const entry = log.entry({ resource }, {
      message: 'Batch executed successfully',
      records: records.length,
    });
    await log.write(entry);
  } catch (err) {
    console.log(`Batch error: ${err}`);
    const entry = log.entry({ resource }, {
      message: 'Batch execution failed',
      error: err.message,
    });
    await log.write(entry);
  }
  return;
}

async function importCsv(csvFilename) {
  const parser = csv.parse({ columns: true, delimiter: ',' }, async function (err, records) {
    if (err) {
      console.error('Error parsing CSV:', err);
      const entry = log.entry({ resource }, {
        message: 'Error parsing CSV',
        error: err.message,
      });
      await log.write(entry);
      return;
    }
    try {
      console.log('Call write to Firestore');
      await writeToFirestore(records);
      // await writeToDatabase(records);
      console.log(`Wrote ${records.length} records`);
      // A text log entry
      const success_message = `Success: importTestData - Wrote ${records.length} records`;
      const entry = log.entry(
        { resource: resource },
        { message: `${success_message}` }
      );
      await log.write([entry]);
    } catch (e) {
      console.error(e);
      const entry = log.entry({ resource }, {
        message: 'Error during CSV import',
        error: e.message,
      });
      await log.write(entry);
      process.exit(1);
    }
  });

  await fs.createReadStream(csvFilename).pipe(parser);
}

if (process.argv.length < 3) {
  console.error('Please include a path to a csv file');
  process.exit(1);
}

importCsv(process.argv[2]).catch(e => console.error(e));