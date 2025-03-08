const massive = require("massive");
const { faker } = require("@faker-js/faker");

massive({
  host: "localhost",
  port: 5432,
  database: "mydb",
  user: "tin",
  application_name: "nodejs",
  poolSize: 90,
  password: "tin",
}).then(async (db) => {
  console.log("Connected to database");
  try {
    await db.withTransaction(async (tx) => {
      const batchInsertPromises = [];
      for (let i = 1; i < 3; i++) {
        batchInsertPromises.push(funcA(tx, i));
      }
      const result = await Promise.all(batchInsertPromises);
    });
  } catch (error) {
    console.log("5 error outer", error);
  }
});

async function funcA(tx, index) {
  const result = await tx.query(
    `
    update employees set salary = ` +
      333333 +
      ` where id= ` +
      index +
      ";"
  );
  await new Promise((a, b) => setTimeout(a, 4000 - index * 10));
  if (index === 1) {
    console.log("2-throw");
    throw new Error("random error");
  } else {
    console.log("1-query");
    const beforeWait = performance.now();
    tx.query(
      `
        select pg_sleep(10);
        `
    );
    const result = await tx.query(
      `
        select pg_sleep(3);
        update employees set salary = ` +
        333333 +
        ` where id= ` +
        index +
        ";"
    );
    console.log(
      "3-wait 13 seconds for the already issued queries to finished before closing connection",
      result,
      (performance.now() - beforeWait) / 1000
    );
    try {
      console.log("4-query after connection is closed");
      const result3 = await tx.query(
        `
          select pg_sleep(300);
          select * from employees limit 2;
         `
      );
    } catch (error) {
      console.log(
        "6-error because of the query after connection is closed",
        error
      );
    }
    console.log("7-return");
  }
  return result;
}
