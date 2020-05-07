DROP DATABASE IF EXISTS RDBMSProject_19200161;
CREATE DATABASE RDBMSProject_19200161;
USE RDBMSProject_19200161;

CREATE TABLE Stream (
	StreamID INTEGER,
	Stream VARCHAR(50) NOT NULL,
    PRIMARY KEY (StreamID)
    );
 
CREATE TABLE Student (
	StudentID INTEGER,
	FirstName VARCHAR(20) NOT NULL,
    LastName VARCHAR(20) NOT NULL,
	StreamID INTEGER,
	DOB DATE NOT NULL,
	Gender ENUM('Male', 'Female'),
	Nationality VARCHAR(50) NOT NULL,
	GPA DECIMAL(3,2) NOT NULL,
    PRIMARY KEY (StudentID),
    foreign key (StreamID) references Stream(StreamID)
	);

CREATE TABLE Supervisor (
	SupervisorID INTEGER,
	FirstName VARCHAR(20) NOT NULL,
    LastName VARCHAR(20) NOT NULL,
	StreamID INTEGER,
	DOB DATE NOT NULL,
	Gender ENUM('Male', 'Female'),
	Nationality VARCHAR(50) NOT NULL,
    PRIMARY KEY (SupervisorID),
    foreign key (StreamID) references Stream(StreamID)
);

 CREATE TABLE Project(
	ProjectID INTEGER,
    StreamDesignator VARCHAR(20),
    Title VARCHAR(70) NOT NULL UNIQUE,
    PRIMARY KEY (ProjectID)
    );

   CREATE TABLE Student_Project_Map(
	ProjectID INTEGER NOT NULL,
    StudentID INTEGER NOT NULL UNIQUE,
    SupervisorID INTEGER NOT NULL,
    PRIMARY KEY (ProjectID),
    foreign key (StudentID) references Student(StudentID),
    foreign key (SupervisorID) references Supervisor(SupervisorID),
    foreign key (ProjectID) references Project(ProjectID)
    );
    
    CREATE TABLE Student_Pref_alloc (
     StudentID INTEGER,
     preference_allocated INTEGER,
     PRIMARY KEY (StudentID),
     foreign key (StudentID) references Student(StudentID)
     );
    
   CREATE TABLE Student_Preference(
    StudentID INTEGER NOT NULL,
    Pref_1 INTEGER NOT NULL,
    Pref_2 INTEGER,
	Pref_3 INTEGER,
    Pref_4 INTEGER,
    Pref_5 INTEGER,
    Pref_6 INTEGER,
    Pref_7 INTEGER,
    Pref_8 INTEGER,
    Pref_9  INTEGER,
    Pref_10 INTEGER,
    Pref_11 INTEGER,
    Pref_12 INTEGER,
    Pref_13 INTEGER,
    Pref_14 INTEGER,
    Pref_15 INTEGER,
    Pref_16 INTEGER,
    Pref_17 INTEGER,
    Pref_18 INTEGER,
    Pref_19 INTEGER,
    Pref_20 INTEGER,
    PRIMARY KEY (StudentID),
	foreign key (StudentID) references Student(StudentID),
    foreign key (Pref_1)  references Project(ProjectID),
    foreign key (Pref_2)  references Project(ProjectID),
    foreign key (Pref_3)  references Project(ProjectID),
    foreign key (Pref_4)  references Project(ProjectID),
    foreign key (Pref_5)  references Project(ProjectID),
    foreign key (Pref_6)  references Project(ProjectID),
    foreign key (Pref_7)  references Project(ProjectID),
    foreign key (Pref_8)  references Project(ProjectID),
    foreign key (Pref_9)  references Project(ProjectID),
    foreign key (Pref_10)  references Project(ProjectID),
    foreign key (Pref_11)  references Project(ProjectID),
    foreign key (Pref_12)  references Project(ProjectID),
    foreign key (Pref_13)  references Project(ProjectID),
    foreign key (Pref_14)  references Project(ProjectID),
    foreign key (Pref_15)  references Project(ProjectID),
    foreign key (Pref_16)  references Project(ProjectID),
    foreign key (Pref_17)  references Project(ProjectID),
    foreign key (Pref_18)  references Project(ProjectID),
    foreign key (Pref_19)  references Project(ProjectID),
    foreign key (Pref_20)  references Project(ProjectID)
    );
   
   CREATE TABLE Student_Satisfaction(
   StudentID INTEGER,
   Student_Satisfaction_Score INTEGER,
   PRIMARY KEY (StudentID),
   foreign key (StudentID) references Student(StudentID)
   );

   CREATE TABLE Supervisor_Satisfaction(
   SupervisorID INTEGER,
   Supervisor_Satisfaction_Score INTEGER default 0,
   PRIMARY KEY (SupervisorID),
   foreign key (supervisorID) references Supervisor(SupervisorID)
   );
   
   CREATE TABLE Student_Proposed_Project(
   StudentID INTEGER UNIQUE,
   ProjectID INTEGER,
   Supervisor_Approached INTEGER NOT NULL,
   PRIMARY KEY(ProjectID),
   foreign key (studentID) references Student(StudentID),
   foreign key (Supervisor_Approached) references Supervisor(SupervisorID),
   foreign key (ProjectID) references Project(ProjectID)
   );
   
   CREATE TABLE Supervisor_Proposed_Project(
   SupervisorID INTEGER,
   ProjectID INTEGER,
   PRIMARY KEY(ProjectID),
   foreign key (supervisorID) references Supervisor(SupervisorID),
   foreign key (ProjectID) references Project(ProjectID)
   );
   
################## ----------------------Stored Procedures and Triggers--------------------------########################################

# 1. To validate Student by checking the age greater than 18 and GPA between 0 and 4.2

###  STORED PROCEDURE 

DROP PROCEDURE IF EXISTS validate_Student;
DELIMITER $$
CREATE PROCEDURE validate_Student(
    IN DOB date,
	IN GPA DECIMAL 
)
DETERMINISTIC
BEGIN
	IF (SELECT FLOOR(GPA-0)) <= 0.00 THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'GPA must be Greater than 0';
	END IF;
    IF GPA > 4.20 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'GPA must be lesser than 4.2';
	END IF;
	IF (SELECT FLOOR(DATEDIFF(NOW(), DATE(DOB))/365)) < 18 THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Age must be Greater than 18';
	END IF;
END$$
DELIMITER ;

### TRIGGER to call that Relavent Procedure

DELIMITER $$
CREATE TRIGGER validate_Student_insert
before INSERT ON Student FOR EACH ROW
BEGIN
	CALL validate_Student(NEW.DOB, NEW.GPA);
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER validate_Student_update
Before UPDATE ON Student FOR EACH ROW
BEGIN
	CALL validate_Student(NEW.DOB, NEW.GPA);
END$$
DELIMITER ;

#---------------------------------------------------------------------------------------------------------------------
# 2. procedure to check if the a project is both Student and Supervisor Proposed

# A project should either be student Proposed or Supervisor proposed and not both 

DROP PROCEDURE IF EXISTS CheckProposal;
DELIMITER $$
CREATE PROCEDURE CheckProposal()
BEGIN
IF(
select count(*) from supervisor_proposed_project supproj inner join student_proposed_project stuproj on supproj.ProjectID = Stuproj.ProjectID
)!=0 THEN
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'The Project has already been Proposed by the supervisor';
END IF;
END$$
DELIMITER ;

# Relevent Trigger to call the procedure

DELIMITER $$
CREATE TRIGGER validate_Proposal
after INSERT ON Student_Proposed_Project FOR EACH ROW
BEGIN
	CALL CheckProposal();
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER validate_Proposal_update
after UPDATE ON Student_Proposed_Project FOR EACH ROW
BEGIN
	CALL CheckProsal();
END$$
DELIMITER ;

#---------------------------------------------------------------------------------------------------------------------
# 3. validation Student Project Map table to see if the hard constraint; Every student must be allocated a project from his/her own Stream 

DROP PROCEDURE IF EXISTS procedureTestStream;
DELIMITER $$
CREATE PROCEDURE procedureTestStream()
BEGIN
IF(select count(s.StudentID) from Student_Project_Map s inner join Project p on s.ProjectID=p.ProjectID 
inner join Student st on s.StudentID=st.StudentID 
inner join Stream sr on st.StreamID =sr.StreamID where ((sr.Stream != p.StreamDesignator) AND (p.streamDesignator!='CS/CS+DS')))!=0 THEN
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'The Students have been Allocated to wrong Project Stream by the Algorithm';
END IF;
END$$
DELIMITER ;

# Trigger for relevent Procedure

DELIMITER $$
CREATE TRIGGER validate_allocation
after INSERT ON Student_Project_Map FOR EACH ROW
BEGIN
	CALL procedureTestStream();
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER validate_allocation_update
after UPDATE ON Student_Project_Map FOR EACH ROW
BEGIN
	CALL procedureTestStream();
END$$
DELIMITER ;


#---------------------------------------------------------------------------------------------------------------------
# 4. Verify that the 1st Prefernece must not be null and must always be from the branch of the student 

DROP PROCEDURE IF EXISTS CheckPref_1;
DELIMITER $$
CREATE PROCEDURE CheckPref_1()
BEGIN
IF(
select count(s.StudentID) from Student_Preference sp inner join Project p on sp.Pref_1= p.ProjectID
 inner join Student s on  sp.StudentID = s.StudentID inner join Stream sr on s.StreamID = sr.StreamID 
 where p.StreamDesignator <> sr.Stream AND p.StreamDesignator <> 'CS/CS+DS' 
)!=0 THEN
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'The 1st preference of project you provided should belong either to your stream or CS/CS+DS.';
END IF;
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER validate_Pref_1
after INSERT ON Student_Preference FOR EACH ROW
BEGIN
	CALL CheckPref_1();
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER validate_Pref_1_update
after UPDATE ON Student_Preference FOR EACH ROW
BEGIN
	CALL CheckPref_1();
END$$
DELIMITER ;

#---------------------------------------------------------------------------------------------------------------------
 # Procedure  to extract the preferece column and insert it into a table 
 
DROP PROCEDURE IF EXISTS fetch_prefnum;
DELIMITER $$
CREATE PROCEDURE fetch_prefnum()
BEGIN
 DECLARE done BOOLEAN DEFAULT FALSE;
  DECLARE _id BIGINT UNSIGNED;
  DECLARE cur CURSOR FOR SELECT StudentID from Student_Project_Map;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done := TRUE;

  OPEN cur;

  testLoop: LOOP
    FETCH cur INTO _id;
    IF done THEN
      LEAVE testLoop;
    END IF;
	call updater(_id);
  END LOOP testLoop;

  CLOSE cur;
END$$
DELIMITER ;


#################################################
DROP PROCEDURE IF EXISTS updater;
DELIMITER $$
CREATE PROCEDURE updater(
    IN ID INTEGER
)
DETERMINISTIC
BEGIN
			  set @pref =( select ProjectID from Student_Project_Map where StudentID=ID limit 1);
  
  set@pref_alloted= (SELECT col FROM (

   SELECT "Pref_1" AS col, Pref_1, StudentID AS value FROM Student_Preference where Pref_1 =@pref
   UNION ALL SELECT "Pref_2", Pref_2, StudentID FROM Student_Preference where Pref_2 =@pref
   UNION ALL SELECT "Pref_3", Pref_3,StudentID FROM Student_Preference where Pref_3 =@pref
   UNION ALL SELECT "Pref_4",Pref_4, StudentID FROM Student_Preference where Pref_4 =@pref
   UNION ALL SELECT "Pref_5", Pref_5,StudentID FROM Student_Preference where Pref_5 =@pref
   UNION ALL SELECT "Pref_6",Pref_6, StudentID FROM Student_Preference where Pref_6 =@pref
   UNION ALL SELECT "Pref_7",Pref_7, StudentID FROM Student_Preference where Pref_7 =@pref
   UNION ALL SELECT "Pref_8", Pref_8,StudentID FROM Student_Preference where Pref_8 =@pref
   UNION ALL SELECT "Pref_9",Pref_9, StudentID FROM Student_Preference where Pref_9 =@pref
   UNION ALL SELECT "Pref_10", Pref_10,StudentID FROM Student_Preference where Pref_10 =@pref
   UNION ALL SELECT "Pref_11",Pref_11, StudentID FROM Student_Preference where Pref_11 =@pref
   UNION ALL SELECT "Pref_12", Pref_12,StudentID FROM Student_Preference where Pref_12 =@pref
   UNION ALL SELECT "Pref_13",Pref_13, StudentID FROM Student_Preference where Pref_13 =@pref
   UNION ALL SELECT "Pref_14",Pref_14, StudentID FROM Student_Preference where Pref_14 =@pref
   UNION ALL SELECT "Pref_15",Pref_15, StudentID FROM Student_Preference where Pref_15 =@pref
   UNION ALL SELECT "Pref_16", Pref_16,StudentID FROM Student_Preference where Pref_16 =@pref
   UNION ALL SELECT "Pref_17",Pref_17, StudentID FROM Student_Preference where Pref_17 =@pref
   UNION ALL SELECT "Pref_18",Pref_18, StudentID FROM Student_Preference where Pref_18 =@pref
   UNION ALL SELECT "Pref_19",Pref_19, StudentID FROM Student_Preference where Pref_19=@pref
   UNION ALL SELECT "Pref_20",Pref_20, StudentID FROM Student_Preference where Pref_20 =@pref
) allValues WHERE value = ID limit 1) ;


set @pref_num =(select substring(@pref_alloted, 6)limit 1);
IF (SELECT EXISTS(SELECT StudentID from Student_Proposed_Project WHERE StudentID=ID limit 1))=1 THEN
		set @pref_num =1;
	END IF;

INSERT into Student_Pref_alloc values
(ID, @pref_num);
END$$
DELIMITER ;


#---------------------------------------------------------------------------------------------------------------------
# procedure to calculate and fill the Student satisfaction Table

DROP PROCEDURE IF EXISTS insertsat;
DELIMITER $$
CREATE PROCEDURE insertsat()
BEGIN
 DECLARE done BOOLEAN DEFAULT FALSE;
  DECLARE _id BIGINT UNSIGNED;
  DECLARE cur CURSOR FOR SELECT StudentID from Student_Project_Map;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done := TRUE;

  OPEN cur;

  testLoop: LOOP
    FETCH cur INTO _id;
    IF done THEN
      LEAVE testLoop;
    END IF;
	call satisfaction_insert(_id);
  END LOOP testLoop;

  CLOSE cur;
END$$
DELIMITER ;



DROP PROCEDURE IF EXISTS satisfaction_insert;
DELIMITER $$
CREATE PROCEDURE satisfaction_insert(
    IN ID INTEGER
)
DETERMINISTIC
BEGIN
	set @pref =( select preference_allocated from Student_Pref_alloc where StudentID=ID limit 1);
    set @sat_score = 105-(@pref * 5);
   
Insert into Student_satisfaction values
(ID, @sat_score);
END$$
DELIMITER ;




#---------------------------------------------------------------------------------------------------------------------

# Procedure to calculate and fill the Supervisor Satisfaction scores

CREATE VIEW `Supervisor_Project_Count` AS
select count(spm.ProjectID) as 'num', spm.SupervisorID, s.FirstName, s.LastName from Student_Project_Map spm inner join Supervisor s on s.SupervisorID = spm.SupervisorID group by SupervisorID; 


DROP PROCEDURE IF EXISTS satisfaction_supervisor;
DELIMITER $$
CREATE PROCEDURE satisfaction_supervisor()
BEGIN
 DECLARE done BOOLEAN DEFAULT FALSE;
  DECLARE _id BIGINT UNSIGNED;
  DECLARE cur CURSOR FOR SELECT SupervisorID from Supervisor;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done := TRUE;

  OPEN cur;

  testLoop: LOOP
    FETCH cur INTO _id;
    IF done THEN
      LEAVE testLoop;
    END IF;
	call supervisor_Satisfaction(_id);
  END LOOP testLoop;

  CLOSE cur;
END$$
DELIMITER ;


DROP PROCEDURE IF EXISTS supervisor_Satisfaction;
DELIMITER $$
CREATE PROCEDURE supervisor_Satisfaction(
    IN SupID INTEGER
)
DETERMINISTIC
BEGIN
	
    set @count = (select num from Supervisor_Project_count where SupervisorID=supID limit 1 );
     set @sup_sat = (1/@count) * 100;
     IF (SELECT EXISTS(SELECT SupervisorID from Supervisor_Project_count WHERE SupervisorID=supID limit 1))=0 THEN
		set @sup_sat =0;
	End If;
Insert into Supervisor_satisfaction values
(supID, @sup_sat);
END$$
DELIMITER ;




##################################################################################################################### POPULATING THE TABLES #######################################################################################################

INSERT INTO Stream VALUES
 (1, 'CS'),
 (2, 'CS+DS');
 

INSERT INTO Student VALUES
(1, 'Mano', 'Rentoll', 1, '1997-10-23', 'Male', 'Portugal', 3.56),
(2, 'Elias', 'Burge', 2, '1995-11-19', 'Male', 'France', 2.5),
(3, 'Courtnay', 'Basili', 1, '1992-12-22', 'Female', 'Indonesia', 3.31),
(4, 'Dorelia', 'Ragbourne', 2, '1998-03-23', 'Female', 'Brazil', 3.8),
(5, 'Ravish', 'Kumar', 2, '1998-02-26', 'Female', 'India', 3.59),
(6, 'Deepika', 'Yadav',2, '1990-08-06', 'Female', 'India', 3.77),
(7, 'Esta','Alner', 1, '1993-02-15', 'Female', 'Poland', 3.92),
(8, 'Earlie', 'Ferrulli', 1, '1991-01-09', 'Male', 'Ireland', 2.68),
(9, 'Melany', 'Frodsam', 1, '1994-12-08', 'Female', 'France', 2.61),
(10, 'Donaugh', 'Irnys', 1, '1991-01-26', 'Male', 'Germany', 2.76),
(11, 'Mellisa', 'Challiner', 2, '2000-12-10', 'Female', 'Libya', 3.72),
(12, 'Daveta', 'Grice', 1, '1999-04-23', 'Female', 'Ireland', 3.24),
(13, 'Randolph', 'Schulz', 1, '1993-01-20', 'Male', 'Spain', 2.7),
(14, 'Bobbi', 'Clever',2, '1992-01-24', 'Female', 'Czech Republic', 3.55),
(15, 'Jeannette', 'Dorber', 1, '1997-09-13', 'Female', 'United Kingdom', 2.97),
(16, 'Hollyanne', 'Hurdle', 1, '1994-11-08', 'Female', 'Kazakhstan', 3.3),
(17, 'Egor', 'Gabbitas', 1, '1995-06-26', 'Male', 'Indonesia', 2.73),
(18, 'Andriette', 'McFater', 1, '1991-07-27', 'Female', 'United States', 4.16),
(19, 'Onida', 'Valti', 2, '1992-03-07', 'Female', 'China', 2.15),
(20, 'Lisetta', 'Denzey', 2, '1998-11-23', 'Female', 'United States', 3.64);    

INSERT INTO Supervisor VALUES
(1, 'Mack', 'Dennett', 2, '1963-07-17', 'Male', 'France'),
(2, 'Jenny', 'Hawket', 1, '1971-09-27', 'Female', 'France'),
(3, 'Lonni', 'Whitehall', 2, '1967-12-04', 'Female', 'France'),
(4, 'Catlin', 'Shawl', 2, '1972-12-08', 'Female', 'France'),
(5, 'Abelard', 'Haskett', 1, '1965-03-06', 'Male', 'Germany'),
(6, 'Bobby', 'Pretsell', 2, '1968-03-28', 'Male', 'United States'),
(7, 'Jorie', 'Bridgwater', 1, '1961-07-29', 'Female', 'Sweden'),
(8, 'Grazia', 'Pitbladdo', 2, '1963-10-26', 'Female', 'Sweden'),
(9, 'Freemon', 'Guilaem', 1, '1969-10-17', 'Male', 'France'),
(10, 'Hewett', 'Vose', 1, '1979-09-13', 'Male', 'France'),
(11, 'Chrisse', 'Mateos', 2, '1966-10-08', 'Male', 'Italy'),
(12, 'Georgette', 'Gravenall', 2, '1963-11-03', 'Female', 'Ireland'),
(13, 'Johan', 'Gogie', 1, '1973-05-24', 'Male', 'Sweden'),
(14, 'Jephthah', 'Muzzollo', 1, '1961-06-03', 'Male', 'France'),
(15, 'Gannie', 'Ginnety', 1, '1962-12-28', 'Male', 'United States');

INSERT INTO Project VALUES
    (121, 'CS', 'Whispers from Rlyeh Monitoring application'),
    (123, 'CS+DS', 'Cthulhu Crusades website'),
	(182, 'CS', 'The great Haozhorh App'),
	(128, 'CS', 'Daredevil Vothrhorc Skiing app '),
    (153, 'CS+DS', "The life of D'aioct'itroth Website"),
    (120, 'CS+DS', 'The last of Avhaiognne Game application'),
    (803, 'CS', 'The Great Ybharvurc App'),
    (132, 'CS', "Incarnations of Unurv'gna website "),
    (334, 'CS', "The foreign Land of Cxylth'therc"),
    (1221, 'CS', "Monster Mlagh'tho and its rampage"),
    (1232, 'CS/CS+DS', "Secrets of Nol'thug"),
    (9841, 'CS', "Dangerous Aiuez'agos"),
    (42121,'CS/CS+DS', "Traiobb'dhrin"),
    (873,'CS', "Killing of D'othrex"),
    (553, 'CS', 'Adventures of Vhuidrratl Game'),
    (146, 'CS', 'Hulal, the tracking app'),
    (110, 'CS/CS+DS', 'Mysteries in Azuithlir'),
    (786, 'CS+DS', "Mafia Yimh'ibrod"),
    (313,'CS+DS', 'Love of Aiubralpeg'),
    (93621, 'CS', "Invincible Izaiombr'dre"),
    (282, 'CS', " Killer Iaz'eggdi"),
    (1023, 'CS+DS', 'The temple of dagons'),
    (1421, 'CS+DS', 'Great Old Ones'),
    (520, 'CS+DS', 'Cathulu owns Batman'),
    (89721, 'CS', 'Pulp cathulu'),
    (34213, 'CS+DS', "The rising Evug'dri");


INSERT INTO Student_Project_Map (ProjectID, StudentID, SupervisorID) values
(873, 1,5),
(182, 3, 15),
(123,2,1),
(153, 4,8),
(120,5,12),
(313,6,12),
(128,7,14),
(803,8,14),
(132,9,10),
(334,10,7),
(1232,11,8),
(1221,12,5),
(9841,13,2),
(1023,14,3),
(146,15,13),
(93621,16,13),
(282,17,15),
(89721,18,7),
(520,19,4),
(1421,20,6);


INSERT INTO Student_Preference VALUES
(1, 873,803,153,182,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null),
(2, 153,123,1232,42121,786,313,520,34213,null,null,null,null,null,null,null,null,null,null,null,null),
(3, 182,121,146,9841,1221,132,803,553,42121,110,null,null,null,null,null,null,null,null,null,null),
(4, 123,1023,153,520,34213,313,786,153,123,null,null,null,null,null,null,null,null,null,null,null),
(5, 110,120,182,42121,520,34213,153,null,null,null,null,null,null,null,null,null,null,null,null,null),
(6, 313,110,153,42121,520,34213,153,null,null,null,null,null,null,null,null,null,null,null,null,null),
(7, 803,146,121,182,128,1221,132,553,42121,110,null,null,null,null,null,null,null,null,null,null),
(8, 553,182,128,1221,132,803,42121,110,182,null,null,null,null,null,null,null,null,null,null,null),
(9, 803,146,121,132,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null),
(10, 42121,334,121,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null),
(11, 1232,123,786,1232,42121,34213,313,520,null,null,null,null,null,null,null,null,null,null,null,null),
(12, 132,1221,121,9841,42121,110,null,null,null,null,null,null,null,null,null,null,null,null,null,null),
(13, 146,121,182,9841,1232,1221,132,803,553,42121,110,128,34213,146,93621,null,null,null,null,null),
(14, 153,123,1023,42121,786,313,520,34213,null,null,null,null,null,null,null,null,null,null,null,null),
(15, 146,146,146,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null),
(16, 182,121,146,93621,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null),
(17, 282,9841,1221,803,553,132,182,121,146,42121,110,null,null,null,null,null,null,null,null,null),
(18, 89721,132,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null),
(19, 153,123,1232,42121,313,786,520,34213,null,null, null,null,null,null,null,null,null,null,null,null),
(20, 1421,1221,132,803,553,786,313,182,520,34213,null,null,null,null,null,null,null,null,null,null);

INSERT into Student_Proposed_Project values
(1,873,5),
(5,120,12),
(10,334,7),
(17,282,15),
(18,89721,7),
(20,1421,6);

INSERT into Supervisor_Proposed_Project values
(7,121),
(1,123),
(15,182),
(9,128),
(8,153),
(14,803),
(10,132),
(5,1221),
(8,1232),
(2,9841),
(2,42121),
(1,553),
(13,146),
(5,110),
(3,786),
(12,313),
(13,93621),
(3,1023),
(4,520),
(6,34213);

# call the procedure to update the student Project Map table
call fetch_prefnum();

# call the procedure to calculate and populate the Supervisor satisfaction Score
call satisfaction_supervisor();

# call the procedure to calculate and populate the Student Satisfaction Score
call insertsat();

select * from Student_pref_alloc;
#################################################################################################################
#####------------------------- VIEWS-----------------------------------#########

 CREATE VIEW `Post_Allocation_Available_Projects` AS 
 SELECT * FROM Project as p WHERE NOT EXISTS 
 ( SELECT * FROM Student_Project_Map as spm
       WHERE spm.ProjectID = p.ProjectID );
       
select * from Post_Allocation_Available_Projects;

#----------------------------------------------------

 CREATE VIEW `Project_Supervisor_Association` AS 
select combine.ProjectID, p.Title, combine.Supervisor, sp.FirstName, sp.LastName from 
(select Supervisor_Approached as Supervisor, ProjectID from Student_Proposed_Project Union all (select SupervisorID, ProjectID from Supervisor_Proposed_project)) as combine
 inner join Supervisor sp on combine.Supervisor=sp.SupervisorID
 inner join Project p on combine.ProjectID=p.ProjectID ;  
 
 select * from Project_Supervisor_Association;
 
 #-------------------------------------------------------

CREATE VIEW `sample_Student_view` AS 
select * from Project
WHERE ( ProjectID not in (select ProjectID from Student_Proposed_Project)
OR ProjectID in (select ProjectID from Student_Proposed_Project where StudentID=5))
and( StreamDesignator= (select sr.Stream from Stream sr inner join  Student s on s.StreamID=sr.StreamID where s.StudentID=5) OR StreamDesignator='CS/CS+DS') ;

select * from sample_Student_view;

#------------------------------------------------------



####################################################################################-------------------- QUERIES--------------------------############################################################################################################################

#####################################----------------------- QUERY 1: Find the number of Projects Allocated to each Supervisor------------------------------#################################

select count(spm.ProjectID) as 'Number of Projects Allocated', spm.SupervisorID, s.FirstName, s.LastName from Student_Project_Map spm inner join Supervisor s on s.SupervisorID = spm.SupervisorID group by SupervisorID; 

#####################################----------------------- QUERY 2: Find the Most Popular Project ------------------------------#####################################
select a.Title, a.ProjectID, b.Popularity
from Project as a
inner join 
(
  select project , count(*) as Popularity 
from (
		(select Pref_1 as project from Student_Preference ) union all
		(select Pref_2 as project from Student_Preference) union all (select Pref_3 as project from Student_Preference)
     ) p
group by project
) as b
on a.ProjectID=b.project order by b.popularity DESC limit 5;

#####################################----------------------- QUERY 3: Find how popular each project was from the number of times it  appears in the preference ------------------------------#####################################

select distinct a.Title, a.ProjectID, b.Num_of_Occurence
from Project as a
inner join 
(
  select project , count(*) as Num_of_Occurence 
from (
		(select Pref_1 as project from Student_Preference ) union all
      (select Pref_2 as project from Student_Preference) union all (select Pref_3 as project from Student_Preference) union all (select Pref_4 as project from Student_Preference) union all (select Pref_5 as project from Student_Preference) 
       union all (select Pref_6 as project from Student_Preference) union all (select Pref_7 as project from Student_Preference) union all  (select Pref_8 as project from Student_Preference) union all (select Pref_9 as project from Student_Preference)
	   union all(select Pref_10 as project from Student_Preference) union all (select Pref_11 as project from Student_Preference) union all(select Pref_12 as project from Student_Preference) union all (select Pref_13 as project from Student_Preference)
        union all(select Pref_14 as project from Student_Preference) union all (select Pref_15 as project from Student_Preference) union all(select Pref_16 as project from Student_Preference) union all (select Pref_17 as project from Student_Preference)
         union all(select Pref_18 as project from Student_Preference) union all (select Pref_19 as project from Student_Preference) union all (select Pref_20 as project from Student_Preference) 

     ) p
group by project
) as b
on a.ProjectID=b.project order by b.Num_of_Occurence ;

#####################################----------------------- QUERY 4: Find the number of student proposed projects in each stream ------------------------------#####################################

select count(std.StudentID) as 'Number of self Proposed Projects', sr.Stream  from Student_Proposed_Project spm inner join Student std on spm.StudentID = std.StudentID inner join Stream sr on std.StreamID=sr.StreamID  group by sr.Stream;


#####################################----------------------- QUERY 5: Supervisors who did not get any project ------------------------------#####################################
select SupervisorID, FirstName, LastName from Supervisor where SupervisorID not in (select SupervisorID from Student_Project_Map);

####################################------------------------Query 6 Supervisors who proposed projects from streams other than their own Stream--------------------###################################

select spm.supervisorID, spm.ProjectID,p.Title, p.StreamDesignator as 'Project Stream', s.FirstName, s.LastName, sr.Stream as 'Supervisor Stream'  from Supervisor_Proposed_Project spm  inner join Project p on spm.ProjectID = p.ProjectID inner join Supervisor s on spm.SupervisorID = s.SupervisorID inner join Stream sr on s.StreamID=sr.StreamID where p.StreamDesignator<>sr.Stream ;

####################################------------------------Query 7 GPA of the Students who has the same Preference at Possition 1--------------------###################################

Select sf.StudentID, sf.Pref_1 as '1st Preference' ,p.Title, s.FirstName, s.LastName, s.GPA from Student_Preference sf inner join Student s on sf.StudentID = s.StudentID inner join Project p on sf.Pref_1= p.ProjectID where Pref_1 IN (SELECT Pref_1 FROM Student_Preference GROUP BY Pref_1 HAVING COUNT(*) > 1) Order by Pref_1, s.GPA;

##################################------------------------Query 8 : Given a Studen ID find all the prefences which do not belong to his/her stream ########################################
set @x= 13; # Student ID is taken input from the User 

select * from Project  where ProjectID in (
	( select project from ((select Pref_1 as project from Student_Preference where StudentID=@x ) union all
      (select Pref_2 as project from Student_Preference where StudentID=@x) union all 
      (select Pref_3 as project from Student_Preference where StudentID=@x) union all 
      (select Pref_4 as project from Student_Preference where StudentID=@x) union all
      (select Pref_5 as project from Student_Preference where StudentID=@x) union all 
      (select Pref_6 as project from Student_Preference where StudentID=@x) union all 
      (select Pref_7 as project from Student_Preference where StudentID=@x) union all
      (select Pref_8 as project from Student_Preference where StudentID=@x) union all 
      (select Pref_9 as project from Student_Preference where StudentID=@x) union all
      (select Pref_10 as project from Student_Preference where StudentID=@x) union all 
      (select Pref_11 as project from Student_Preference where StudentID=@x) union all
      (select Pref_12 as project from Student_Preference where StudentID=@x) union all 
      (select Pref_13 as project from Student_Preference where StudentID=@x) union all
      (select Pref_14 as project from Student_Preference where StudentID=@x) union all
      (select Pref_15 as project from Student_Preference where StudentID=@x) union all
      (select Pref_16 as project from Student_Preference where StudentID=@x) union all 
      (select Pref_17 as project from Student_Preference where StudentID=@x) union all
      (select Pref_18 as project from Student_Preference where StudentID=@x) union all 
      (select Pref_19 as project from Student_Preference where StudentID=@x) union all
      (select Pref_20 as project from Student_Preference where StudentID=@x)
     ) p
     group by project )
     ) and StreaMDesignator <> ( select sr.Stream from Student s inner join Stream sr on s.StreamID=sr.StreamID where s.StudentID= @x) and StreamDesignator <> 'CS/CS+DS';     
     
###########################---------------------------Query 9: For a given Student show only the eligible projects

select * from Project
WHERE ( ProjectID not in (select ProjectID from Student_Proposed_Project)
OR ProjectID in (select ProjectID from Student_Proposed_Project where StudentID=5))
and( StreamDesignator= (select sr.Stream from Stream sr inner join  Student s on s.StreamID=sr.StreamID where s.StudentID=5) OR StreamDesignator='CS/CS+DS') ;

##################################------------------------Query 10 : Query to find the number of Preferences provided by each student and also calculate the average number of preferences provided ########################################

SELECT 
  (
  IF(Pref_1 IS NOT NULL, 1, 0)
  + IF(Pref_2 IS NOT NULL, 1, 0)
  + IF(Pref_3 IS NOT NULL, 1, 0)
  + IF(Pref_4 IS NOT NULL, 1, 0)
  + IF(Pref_5 IS NOT NULL, 1, 0)
  + IF(Pref_6 IS NOT NULL, 1, 0)
  + IF(Pref_7 IS NOT NULL, 1, 0)
  + IF(Pref_8 IS NOT NULL, 1, 0)
  + IF(Pref_9 IS NOT NULL, 1, 0)
  + IF(Pref_10 IS NOT NULL, 1, 0)
  + IF(Pref_11 IS NOT NULL, 1, 0)
  + IF(Pref_12 IS NOT NULL, 1, 0)
  + IF(Pref_13 IS NOT NULL, 1, 0)
  + IF(Pref_14 IS NOT NULL, 1, 0)
  + IF(Pref_15 IS NOT NULL, 1, 0)
  + IF(Pref_16 IS NOT NULL, 1, 0) 
  + IF(Pref_17 IS NOT NULL, 1, 0)  
  + IF(Pref_18 IS NOT NULL, 1, 0)
  + IF(Pref_19 IS NOT NULL, 1, 0)
  + IF(Pref_20 IS NOT NULL, 1, 0)  
    )
  AS 'Number of pref entered', StudentID
FROM  Student_Preference;

# finding the average number of Prefernces
SELECT 
  Avg(
  IF(Pref_1 IS NOT NULL, 1, 0)
  + IF(Pref_2 IS NOT NULL, 1, 0)
  + IF(Pref_3 IS NOT NULL, 1, 0)
  + IF(Pref_4 IS NOT NULL, 1, 0)
  + IF(Pref_5 IS NOT NULL, 1, 0)
  + IF(Pref_6 IS NOT NULL, 1, 0)
  + IF(Pref_7 IS NOT NULL, 1, 0)
  + IF(Pref_8 IS NOT NULL, 1, 0)
  + IF(Pref_9 IS NOT NULL, 1, 0)
  + IF(Pref_10 IS NOT NULL, 1, 0)
  + IF(Pref_11 IS NOT NULL, 1, 0)
  + IF(Pref_12 IS NOT NULL, 1, 0)
  + IF(Pref_13 IS NOT NULL, 1, 0)
  + IF(Pref_14 IS NOT NULL, 1, 0)
  + IF(Pref_15 IS NOT NULL, 1, 0)
  + IF(Pref_16 IS NOT NULL, 1, 0) 
  + IF(Pref_17 IS NOT NULL, 1, 0)  
  + IF(Pref_18 IS NOT NULL, 1, 0)
  + IF(Pref_19 IS NOT NULL, 1, 0)
  + IF(Pref_20 IS NOT NULL, 1, 0)  
    )
  AS 'Average number of Preferences Entered'
FROM  Student_Preference;

##################################------------------------Query 11 : Query to find all the students who have the maximum satisfaction ########################################

select s.StudentID, s.FirstName, s.LastName, s.GPA, sf.Student_satisfaction_score from Student_satisfaction sf inner join student s on sf.studentId=s.StudentID where sf.Student_satisfaction_score =(select max(Student_satisfaction_score) from Student_satisfaction) ;
     
     
     
     
