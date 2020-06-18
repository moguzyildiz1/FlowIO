//In the HTML, you MUST load all of your service JS files before loading
//this file, because the contents of the function initializeAllService()
//are defined in those service JS files.

//#############################---INIT PARAMETERS---#################################
const DEVICE_NAME_PREFIX = 'FlowIO';
let listOfServices = ['generic_access','battery_service']
//You can find the names of service names defined in the Web Bluetooth API at
//https://googlechrome.github.io/samples/web-bluetooth/characteristic-properties-async-await.html

//This function must contain all of the services that you wish to access:
async function initializeAllServices(){
  await initBatteryService(); //defined in "batteryService.js"
}
function enableControls(){
  document.querySelector('#disconnect_btn').disabled = false;
  document.querySelector('#reconnect_btn').disabled = false;
  document.querySelector('#batt_refresh_btn').disabled = false;

}
function disableControls(){
  document.querySelector('#disconnect_btn').disabled = true;
  document.querySelector('#batt_refresh_btn').disabled = true;
}

//##################################################################################
