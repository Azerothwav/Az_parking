/* ESX Only */
CREATE TABLE `owned_vehicles` (
  `owner` varchar(60) NOT NULL,
  `plate` varchar(12) NOT NULL,
  `vehicle` longtext DEFAULT NULL,
  `model` varchar(60) NOT NULL DEFAULT 'Unknown',
  `vehiclename` varchar(200) DEFAULT NULL,
  `type` varchar(20) NOT NULL DEFAULT 'car',
  `job` varchar(60) DEFAULT NULL,
  `job2` varchar(60) DEFAULT NULL,
  `job3` varchar(60) DEFAULT NULL,
  `stored` tinyint(1) NOT NULL DEFAULT 0,
  `pound` tinyint(1) DEFAULT 0,
  `garage_name` varchar(20) DEFAULT NULL,
  `garage_type` tinyint(4) DEFAULT 1,
  `vip` tinyint(4) DEFAULT 0
);



/* QBCore Only */
ALTER TABLE `player_vehicles` ADD COLUMN `job` varchar(60) DEFAULT NULL;
ALTER TABLE `player_vehicles` ADD COLUMN `vip` varchar(60) DEFAULT NULL;
ALTER TABLE `player_vehicles` ADD COLUMN `vehiclename` varchar(200) DEFAULT NULL;