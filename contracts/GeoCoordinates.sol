// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GeoCoordinates {
    // Structure pour les coordonnées géographiques
    struct Coordinate {
        int256 latitude;
        int256 longitude;
    }

    // Tableau pour stocker les coordonnées
    Coordinate[] public coordinates;

    // Événement déclenché lorsqu'une nouvelle coordonnée est ajoutée
    event CoordinateAdded(int256 latitude, int256 longitude);

    // Fonction pour ajouter une nouvelle coordonnée au tableau
    function addCoordinate(int256 _latitude, int256 _longitude) public {
        coordinates.push(Coordinate(_latitude, _longitude));
        emit CoordinateAdded(_latitude, _longitude);
    }

    // Fonction pour obtenir le nombre total de coordonnées stockées
    function getCoordinatesCount() public view returns (uint256) {
        return coordinates.length;
    }

    // Fonction pour obtenir une coordonnée par son index dans le tableau
    function getCoordinate(uint256 index) public view returns (int256 latitude, int256 longitude) {
        require(index < coordinates.length, "Invalid index");
        Coordinate memory coord = coordinates[index];
        return (coord.latitude, coord.longitude);
    }
}