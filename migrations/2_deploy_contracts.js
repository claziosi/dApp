const GeoCoordinates = artifacts.require("GeoCoordinates");

module.exports = function(deployer) {
    deployer.deploy(GeoCoordinates);
}