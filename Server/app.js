
/**
 * Module dependencies.
 */

var express = require('express');
var routes = require('./routes');
var user = require('./routes/user');
var http = require('http');
var path = require('path');
var MongoClient = require('mongodb').MongoClient;
    
var app = express();

// all environments
app.set('port', process.env.PORT || 3000);
app.set('views', __dirname + '/views');
app.set('view engine', 'ejs');
app.use(express.favicon());
app.use(express.logger('dev'));
app.use(express.bodyParser());
app.use(express.methodOverride());
app.use(app.router);
app.use(express.static(path.join(__dirname, 'public')));

// development only
if ('development' == app.get('env')) {
  app.use(express.errorHandler());
}

app.get('/', routes.index);

app.get('/myfirstapp', function(request, response){
  newUser('myfirstapp', function(result){
    response.send(result);
  });
});

app.get('/mysecondapp', function(request, response){
  newUser('mysecondapp', function(result){
    response.send(result);
  });
});

app.post('/', function(request, response){
  // request.body saved the incoming logs
  if(request.body['Secret']) {
    // get app name 
    var appName;
    if(request.body['Secret'] === 'Secret1') {
      appName = 'myfirstapp';
    }
    else if(request.body['Secret'] === 'Secret2') {
      appName = 'mysecondapp';
    }
    else {
      return;
    }
    
    if(request.body['DEBUG']) {
      appName += '-DEBUG';
    }
    
    var requestIP = request.ip;
    var userAgent =  request.get('user-agent');
    var inputBody = request.body;
    var UUID = inputBody['UUID'];
    
    inputBody['IP'] = requestIP;
    //inputBody['UserAgent'] = userAgent; // useless for now
    var ServerDateTime = getDateTime();
    delete inputBody['UUID'];
    delete inputBody['Secret'];
    
    var lastReachability = '';

    if(inputBody['EventName'].indexOf('SReachability:') > -1) {
       lastReachability = inputBody['EventName'].substring(14);
    }
  
    // save it to the db
    MongoClient.connect('mongodb://127.0.0.1:27017/UDC-'+appName, function(err, db) {
      if(err) throw err;

      var collection = db.collection('users');
      collection.findOne({'UUID': UUID}, function(err, document) {
        if(err) {
          console.error(err);
          return;
        }
        
        if(document == null) {
          // insert the document
          var document = {'UUID':UUID, 
                          'Device':inputBody['Device'],
                          'OSs': [{'name':inputBody['OS'],'time':ServerDateTime}],
                          'OSVersions':[{'version':inputBody['OSVersion'],'time':ServerDateTime}],
                          'AppVersions':[{'version':inputBody['AppVersion'],'time':ServerDateTime}],
                          'Carriers':[{'name':inputBody['Carrier'],'time':ServerDateTime}],
                          'LastOS':inputBody['OS'],
                          'LastOSVersion':inputBody['OSVersion'],
                          'LastAppVersion':inputBody['AppVersion'],
                          'LastCarrier':inputBody['Carrier'],
                          'LastUpdateTime':ServerDateTime,
                          'LastReability': lastReachability,
                          'IP':requestIP,
                          'Events':[{'name':inputBody['EventName'], 'fireTimeLocal':inputBody['EventFireTimeLocal'], 'time':ServerDateTime}],
                          };
                          
          collection.insert(document, {safe: true}, function(err, records){
            if(err) {
              console.error(err);
              return;
            }
          });
        }
        else {
          // if the log is quite new, then update some attributes
          if(document['LastUpdateTime'] < ServerDateTime) {
            // OS
            if(document['LastOS'] != inputBody['OS']) {
              document['OSs'].push({'name':inputBody['OS'],'time':ServerDateTime});
              document['LastOS'] = inputBody['OS'];
            }
            
            // OSVersion
            if(document['LastOSVersion'] != inputBody['OSVersion']) {
              document['OSVersions'].push({'version':inputBody['OSVersion'],'time':ServerDateTime});
              document['LastOSVersion'] = inputBody['OSVersion'];
            }
            
            // AppVersion
            if(document['LastAppVersion'] != inputBody['AppVersion']) {
              document['AppVersions'].push({'version':inputBody['AppVersion'],'time':ServerDateTime});
              document['LastAppVersion'] = inputBody['AppVersion'];
            }
            
            // Carrier
            if(document['LastCarrier'] != inputBody['Carrier']) {
              document['Carriers'].push({'name':inputBody['Carrier'],'time':ServerDateTime});
              document['LastCarrier'] = inputBody['Carrier'];
            }
          
            // overwrite some attributes
            document['Device'] = inputBody['Device'];
            if(lastReachability != '')
              document['LastReability'] = lastReachability;
            document['LastUpdateTime'] = ServerDateTime;
          }
        
          // push the events
          document['Events'].push({'name':inputBody['EventName'], 'fireTimeLocal':inputBody['EventFireTimeLocal'], 'time':ServerDateTime});
          document['IP'] = requestIP;
          
          collection.save(document, {safe: true}, function(err, records){
            if(err) {
              console.error(err);
              return;
            }
          });
        }
        
        // Let's close the db
        db.close();  
      });
      
      /*
      collection.update({'UUID': UUID}, {$push:{'logs': inputBody}},{upsert:true}, function(err, docs) {
        if(err)
          console.error(err);
        // Let's close the db
        db.close();  
      });
      */
      
    });
  }
  else {
    console.log('missing secret or wrong secret');
  }
  response.send("done");
});

http.createServer(app).listen(app.get('port'), function(){
  console.log('Express server listening on port ' + app.get('port') + ' in ' + app.get('env') + ' mode.');
});

function getDateTime() {
  var date = new Date();

  var hour = date.getHours();
  hour = (hour < 10 ? "0" : "") + hour;

  var min  = date.getMinutes();
  min = (min < 10 ? "0" : "") + min;

  var sec  = date.getSeconds();
  sec = (sec < 10 ? "0" : "") + sec;

  var year = date.getFullYear();

  var month = date.getMonth() + 1;
  month = (month < 10 ? "0" : "") + month;

  var day  = date.getDate();
  day = (day < 10 ? "0" : "") + day;

  return year + "-" + month + "-" + day + " " + hour + ":" + min + ":" + sec;
}

function getYesterdayDate() {
  var date = new Date();
  date.setDate(date.getDate() - 1);

  var year = date.getFullYear();

  var month = date.getMonth() + 1;
  month = (month < 10 ? "0" : "") + month;

  var day  = date.getDate();
  day = (day < 10 ? "0" : "") + day;
  
  return year + "-" + month + "-" + day;
}

function newUser(appname, doWithResult) {
  MongoClient.connect('mongodb://127.0.0.1:27017/UDC-'+appname, function(err, db) {
    if(err) throw err;
    
    var today = getDateTime().split(" ")[0];
    var yesterday = getYesterdayDate();
    
    var collection = db.collection('users');
    collection.find({}, function(err, resultCursor) {
      
      var totalUserNumber = 0;
      var newUserNumber = 0;
      var yesterdayNewUserNumber = 0;
      var activeUserNumber = 0;
      var yesterdayActiveUserNumber = 0;
      var launchTime = 0;
      var yesterdayLaunchTime = 0;

      function processItem(err, item) {
        if(item === null) { // All done!
          result = {'totalUserNumber':totalUserNumber,
                    'newUserNumber':newUserNumber, 
                    'yesterdayNewUserNumber':yesterdayNewUserNumber, 
                    'activeUserNumber':activeUserNumber, 
                    'yesterdayActiveUserNumber':yesterdayActiveUserNumber,
                    'launchTime':launchTime,
                    'yesterdayLaunchTime':yesterdayLaunchTime};
          doWithResult(result);
          return; 
        }

        // Total User
        totalUserNumber++;

        // if first event date is today, add one to new user
        firstEventDate = item['Events'][0]['time'].split(" ")[0];
        if(today == firstEventDate) {
          newUserNumber++;
        }
        
        // if first event date is today, add one to new user yesterday
        if(yesterday == firstEventDate) {
          yesterdayNewUserNumber++;
        }
        
        // if last update date is today, add one to active user
        lastUpdateDate = item['LastUpdateTime'].split(" ")[0];
        if(today == lastUpdateDate) {
          activeUserNumber++;
        }
        
        // Iterate event array
        var yesterdayUsed = false;
        for (var i = 0; i < item['Events'].length; i++) {
          var event =  item['Events'][i];
          var eventDate = event['time'].split(" ")[0];
          
          if(event['name'] == 'SDidFinishLaunching' || event['name'] == 'SDidBecomeActiveNotification') {
            // launchTime
            if(today == eventDate) {
              launchTime++;
            }
            
            // yesterdayLaunchTime
            if(yesterday == eventDate) {
              yesterdayLaunchTime++;
            }
          }
          
          // yesterday Active user
          if(yesterdayUsed == false && yesterday == eventDate) {
            yesterdayUsed = true;
          }
        }
        
        if(yesterdayUsed == true) {
          yesterdayActiveUserNumber++;
        }
        
        resultCursor.nextObject(processItem);
      }

      resultCursor.nextObject(processItem);
    });
  });
}