CREATE TABLE IF NOT EXISTS contacts (
  `id` INTEGER PRIMARY KEY AUTO_INCREMENT,
  `name` TEXT,
  `email` TEXT,
  `age` INTEGER
);

INSERT INTO contacts VALUES(1,'Marcos','marcos@gmail.com',35);
INSERT INTO contacts VALUES(2,'Paulo','paulo@paulo.com',28);
