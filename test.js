const massive = require("massive");
const { faker } = require("@faker-js/faker");

// Number of employees to insert (can be dynamically provided)
const numberOfEmployees = 5000;
const getEmployees = (n) => {
  const results = [];
  for (let i = 0; i < n; i++) {
    const firstName = faker.person.firstName();
    const email = faker.internet.email();
    const salary = faker.finance.amount(30000, 90000, 2); // Random salary between 30,000 and 90,000
    const department = faker.commerce.department();

    // Create the insert data for each employee
    results.push({
      first_name: firstName,
      email: email,
      salary: salary,
      department: department,
    });
  }
  return results;
};

massive({
  host: "localhost",
  port: 5432,
  database: "mydb",
  user: "tin",
  application_name: "nodejs",
  poolSize: 10,
  password: "tin",
})
  .then(async (db) => {
    console.log("Connected to database");
    console.log("Seeding...");
    const payload = getEmployees(numberOfEmployees);
    await db.employees.insert(payload);

    const beforeUpdate = performance.now();
    const q1 = db.query(
      `
        UPDATE employees
        SET salary = '${60}'
        WHERE id = 2;
        SELECT pg_sleep(10);  -- 10 second delay on the database side
        select * from employees where id = 2;
        `
    );
    // this is to make sure that q1 is executed 1st
    await new Promise((resolve, rej) => {
      setTimeout(resolve, 0);
    });

    const q2 = db.query(
      `
        UPDATE employees
        SET salary = '${1200}'
        WHERE id = 2
        Returning *
        `
    );
    // select query does not need to wait
    const q3 = db.query(
      `
         select * from employees where id = 2
        `
    );

    q1.then((result) => {
      console.log("query 1", result);
      console.log(
        `First query updated successfully. Took ${
          (performance.now() - beforeUpdate) / 1000
        } s`
      );
    }).catch((err) => {
      console.error("Error first query:", err);
    });

    q2.then((result) => {
      console.log("query 2", result);
      console.log(
        `Second query updated successfully. Took ${
          (performance.now() - beforeUpdate) / 1000
        } s`
      );
    }).catch((err) => {
      console.error("Error Second query:", err);
    });

    q3.then((result) => {
      console.log("query 3", result);
      console.log(
        `3rd query selected successfully. Took ${
          (performance.now() - beforeUpdate) / 1000
        } s`
      );
    }).catch((err) => {
      console.error("Error 3rd query:", err);
    });
  })
  .catch((err) => {
    console.error("Failed to connect to database", err);
  });
