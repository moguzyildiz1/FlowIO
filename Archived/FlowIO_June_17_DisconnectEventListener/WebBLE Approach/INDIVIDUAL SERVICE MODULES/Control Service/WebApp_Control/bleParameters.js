//In the HTML, you MUST load all of your service JS files before loading
//this file, because the contents of the function initializeAllService()
//are defined in those service JS files.

//#############################---INIT PARAMETERS---#################################
const DEVICE_NAME_PREFIX = 'FlowIO';
let listOfServices = ['generic_access','battery_service', controlServiceUUID]
//You can find the names of service names defined in the Web Bluetooth API at
//https://googlechrome.github.io/samples/web-bluetooth/characteristic-properties-async-await.html

//This function must contain all of the services that you wish to access:
async function initializeAllServices(){
  await initControlService(); //defined in "controlService.js"
}
function enableControls(){
  document.querySelector('#disconnect_btn').disabled = false;
  document.querySelector('#port1_chk').disabled = false;
  document.querySelector('#port2_chk').disabled = false;
  document.querySelector('#port3_chk').disabled = false;
  document.querySelector('#port4_chk').disabled = false;
  document.querySelector('#port5_chk').disabled = false;
  document.querySelector('#inflate_btn').disabled = false;
  document.querySelector('#vacuum_btn').disabled = false;
  document.querySelector('#release_btn').disabled = false;
  document.querySelector('#stop_btn').disabled = false;
  document.querySelector('#stopall_btn').disabled = false;

}
function disableControls(){
  document.querySelector('#disconnect_btn').disabled = true;
  document.querySelector('#port1_chk').disabled = true;
  document.querySelector('#port2_chk').disabled = true;
  document.querySelector('#port3_chk').disabled = true;
  document.querySelector('#port4_chk').disabled = true;
  document.querySelector('#port5_chk').disabled = true;
  document.querySelector('#inflate_btn').disabled = true;
  document.querySelector('#vacuum_btn').disabled = true;
  document.querySelector('#release_btn').disabled = true;
  document.querySelector('#stop_btn').disabled = true;
  document.querySelector('#stopall_btn').disabled = true;
}
//##################################################################################
