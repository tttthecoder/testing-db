const massive = require("massive");
const { faker } = require("@faker-js/faker");

// Number of employees to insert (can be dynamically provided)
const numberOfEmployeesPerBatch = 5000;
const numberOfBatches = 60;
const getEmployees = (n) => {
  const results = [];
  for (let i = 0; i < n; i++) {
    const firstName = faker.person.firstName();
    const email = faker.internet.email();
    const salary = faker.finance.amount(30000, 90000, 2); // Random salary between 30,000 and 90,000
    const department = faker.commerce.department();

    // Create the insert promise for each employee
    results.push({
      first_name: firstName,
      email: email,
      salary: salary,
      department: department,
    });
  }
  return results;
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
    // Generate and insert employees dynamically
    const batchInsertPromises = [];
    const beforeInsert = performance.now();
    for (let i = 0; i < numberOfBatches; i++) {
      const payload = getEmployees(numberOfEmployeesPerBatch);
      const batchInsertPromise = db.withTransaction(async (tx) => {
        return await tx.employees.insert(payload);
      });
      batchInsertPromises.push(batchInsertPromise);
    }

    // Wait for all insertions to complete
    Promise.all(batchInsertPromises)
      .then((results) => {
        console.log(`${
          results.flatMap((a) => a).length
        } employees inserted successfully. Took
          ${(performance.now() - beforeInsert) / 1000} s`);
      })
      .catch((err) => {
        console.error("Error inserting employees:", err);
      });
  })
  .catch((err) => {
    console.error("Failed to connect to database", err);
  });
