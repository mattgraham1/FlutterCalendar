// Intiialize the Cloud Functions library
const functions = require('firebase-functions');
const List = require('collections/list');
// Initialize the Firebase application with admin credentials
const admin = require('firebase-admin');
admin.initializeApp();

// Handle firestore new date format
const firestore = new admin.firestore();
const settings = {timestampsInSnapshots: true};
firestore.settings(settings);

// Check for events within a days range and send notications to the associated tokens.
exports.firestoreDebug = functions.https.onRequest((request, response) => {
  var data = [];
  var emailList = new List();

  firestore.collection('calendar_events')
  .get()
  .then(docs => {
    docs.forEach(doc => {
      var timestamp = doc.get('time');
      var eventDate = timestamp.toDate();
      var now = new Date();
      // data.push(eventDate);
      // data.push(now);

      // Check if we have an event within seven days
      if (eventDate.getFullYear() === now.getFullYear() &&
          eventDate.getMonth() === now.getMonth() &&
          eventDate.getDay() === now.getDay())
      {
        // Test of adding emails to a list
        var mail = doc.get('email');
        if(!emailList.has(mail)) {
          emailList.add(mail);          
        }
        data.push(doc.data());
      }
    })

    return emailList;
  })
  // Setup the query to get all the users from the 'users' collection
  .then(emailList => {
    var query = firestore.collection('users')
    emailList.forEach(email => {
      data.push(email);
      query = query.where('email', '==', email.toString());
    })

    return query.get();
  })
  // Get all the tokens from the 'users' collection
  .then(querySnapshot => {
    var tokenList = [];
    // data.push('querySnapshot size: ' + querySnapshot.size);
    querySnapshot.forEach(doc => {
      tokenList.push(doc.get('token'));
    })
    data.push(tokenList);

    return tokenList;
  })
  // Send the push notification to each token
  .then(tokens => {
    tokens.forEach(token => {
      var message = {
        notification: {
          title: 'Event Notification',
          body: 'You have an event coming up...'
        },
        token: token
      };
      data.push(message);

      admin.messaging().send(message);
    })

    response.status(200).send(data);
    return null;
  }).catch(error => {
    console.error(error);
    response.status(501).send('Error from script...');
  });
});