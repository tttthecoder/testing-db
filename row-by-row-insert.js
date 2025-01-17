const massive = require("massive");
const { faker } = require("@faker-js/faker");

// Number of event_stream records to insert per batch
const numberOfRecordsPerBatch = 50000;
const numberOfBatches = 10;

// Function to generate event_stream records
const getEventStreamRecords = (n) => {
  const records = [];
  for (let i = 0; i < n; i++) {
    const profileId = faker.string.uuid(); // Random UUID for profile_id
    const email = faker.internet.email(); // Random email
    const phoneNumber = faker.phone.number(); // Random phone number
    const accountId = faker.string.uuid(); // Random UUID for account_id
    const brandId = faker.string.uuid(); // Random UUID for brand_id
    const outletId = faker.string.uuid(); // Random UUID for outlet_id
    const sourceId = faker.string.uuid(); // Random UUID for source_id
    const sourceType = faker.helpers.arrayElement([
      "CUSTOM_EVENT",
      "SYSTEM_EVENT",
    ]); // Random source type
    const sourceCreatedAt = faker.date.recent(30).toISOString(); // Random recent date
    const sourceUpdatedAt = faker.date
      .between({ from: sourceCreatedAt, to: new Date() })
      .toISOString(); // Random updated date
    const data = { metadata: faker.lorem.paragraph() }; // Random JSON data

    records.push({
      profile_id: profileId,
      email: email,
      phone_number: phoneNumber,
      account_id: accountId,
      brand_id: brandId,
      outlet_id: outletId,
      source_id: sourceId,
      source_type: sourceType,
      source_created_at: sourceCreatedAt,
      source_updated_at: sourceUpdatedAt,
      data: data,
    });
  }
  return records;
};

// Connect to the PostgreSQL database
massive({
  host: "localhost",
  port: 5432,
  database: "mydb",
  user: "tin",
  application_name: "nodejs",
  poolSize: 90,
  password: "tin",
})
  .then((db) => {
    console.log("Connected to database");
    // Generate and insert event_stream records dynamically
    const batchInsertPromises = [];
    const beforeInsert = performance.now();
    for (let i = 0; i < numberOfBatches; i++) {
      const payload = getEventStreamRecords(numberOfRecordsPerBatch);
      const batchInsertPromise = db.withTransaction(async (tx) => {
        const results = [];
        const values = payload.map(
          (item) =>
            `('${item.profile_id}', '${item.email}', '${item.phone_number}', '${
              item.account_id
            }', '${item.brand_id}', '${item.outlet_id}', '${
              item.source_id
            }', '${item.source_type}', '${item.source_created_at}', '${
              item.source_updated_at
            }', '${JSON.stringify(item.data)}')`
        );

        for (let value of values) {
          const query = `
          INSERT INTO public.event_stream (
            profile_id, email, phone_number, account_id, brand_id, outlet_id, 
            source_id, source_type, source_created_at, source_updated_at
            , data
          ) 
          VALUES ${value}
          ON CONFLICT ((md5(data::text)::uuid)) DO NOTHING
          RETURNING *;
        `;
          results.push((await tx.query(query))[0]);
        }
        return results;
      });
      batchInsertPromises.push(batchInsertPromise);
    }
    // Wait for all insertions to complete
    Promise.all(batchInsertPromises)
      .then((results) => {
        console.log(`${
          results.flatMap((a) => a).length
        } event_stream records inserted successfully. Took
          ${(performance.now() - beforeInsert) / 1000} s`);
      })
      .catch((err) => {
        console.error("Error inserting event_stream records:", err);
      });
  })
  .catch((err) => {
    console.error("Failed to connect to database", err);
  });
