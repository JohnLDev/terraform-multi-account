const { ssl } = require('pg/lib/defaults.js');

module.exports = async function (context, req) {
  context.log('HTTP trigger function received a request.');
  context.log(process.env)
  
  try {
  const { Client } = require('pg');

  const connectionObject = {
    user: process.env.PGUSER,
    host: process.env.PGHOST,
    database: process.env.PGDATABASE,
    password: process.env.PGPASSWORD,
    port: process.env.PGPORT,
  }
  
  context.log(connectionObject)
  const pool = new Client({ssl:{rejectUnauthorized:false}, ...connectionObject});
  await pool.connect();

  const result = await pool.query('SELECT NOW()');
  context.log(result);
} catch (error) {
  context.log(error)
}

  const name = req.query.name || (req.body && req.body.name);
  const responseMessage = name
    ? `Hello, ${name}!`
    : 'Pass a name in the query string or in the request body.';

  context.res = {
    status: 200,
    body: responseMessage,
  };
};
