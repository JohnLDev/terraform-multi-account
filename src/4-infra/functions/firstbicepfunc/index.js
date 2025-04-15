module.exports = async function (context, req) {
  context.log('HTTP trigger function received a request.');

  const name = req.query.name || (req.body && req.body.name);
  const responseMessage = name
    ? `Hello, ${name}!`
    : 'Pass a name in the query string or in the request body.';

  context.res = {
    status: 200,
    body: responseMessage,
  };
};
