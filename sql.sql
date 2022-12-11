CREATE TABLE `impounded_vehicles` (
  `plate` varchar(12) NOT NULL,
  `identifier` varchar(60) NOT NULL,
  `officer` varchar(60) DEFAULT NULL,
  `officerjob` varchar(60) DEFAULT NULL,
  `reason` text NOT NULL,
  `fee` double NOT NULL,
  `impoundtime` varchar(255) DEFAULT NULL,
  `parkingprice` double DEFAULT NULL
);

CREATE TABLE `owned_vehicles` (
  `owner` varchar(60) NOT NULL,
  `plate` varchar(12) NOT NULL,
  `vehicle` longtext DEFAULT NULL,
  `model` varchar(60) NOT NULL DEFAULT 'Unknown',
  `vehiclename` varchar(200) DEFAULT NULL,
  `type` varchar(20) NOT NULL DEFAULT 'car',
  `job` varchar(60) DEFAULT NULL,
  `stored` tinyint(1) NOT NULL DEFAULT 0,
  `pound` tinyint(1) DEFAULT 0,
  `garage_time` bigint(10) DEFAULT NULL,
  `garage_name` varchar(20) DEFAULT NULL,
  `garage_type` tinyint(4) DEFAULT 1,
  `location` text DEFAULT NULL
);

CREATE TABLE `vehicle_model_prices` (
  `model` varchar(30) NOT NULL,
  `price` float NOT NULL DEFAULT 0
);
