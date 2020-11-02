-- COMP3311 20T3 Assignment 1
-- Calendar schema
-- Written by Haoyu Yang

-- Types

create type AccessibilityType as enum ('read-write','read-only','none');
create type InviteStatus as enum ('invited','accepted','declined');
create type VisibilityType as enum('public','private');
create type DayOfWeekType as enum('mon','tue','wed','thu','fri','sat','sun');
-- add more types/domains if you want

-- Tables
-- User and Group Entities
create table Users (
	id          serial,
	email       text not null unique,
	name 		text not null,
	password 	text not null,
	is_admin	boolean not null,
	primary key (id)
);

create table Groups (
	id          serial,
	name        text not null,
	primary key (id),
	owner 		serial not null,
	foreign key (owner) references Users(id)
);



-- Calendar Entity
create table Calendars (
	id          	serial,
	name        	text not null,
	colour			text  not null,
	defaultaccess 	AccessibilityType not null,
	primary key (id),
	owner			serial not null,
	foreign key (owner) references Users(id)
);


-- Event Entity Classes
create table Events (
	id          	serial,
	title        	text not null,
	starttime		time,
	endtime			time,
	visibility		VisibilityType not null,
	location 		text,
	Part_Of			serial not null,
	Created_By		serial not null,
	primary key (id),
	foreign key (Part_Of) references Calendars(id),
	foreign key (Created_By) references Users(id)
);

create table alarms (
	event_id		serial,
	alarm			integer,
	primary key (event_id, alarm),
	foreign key (event_id) references Events(id)
);

create table OneDayEvents (
	event_id		serial,
    date 			date not null,
	primary key (event_id),
    foreign key (event_id) references Events (id)
);

create table SpanningEvents (
    event_id		serial,
    startdate 		date not null,
	enddate			date not null,
	primary key (event_id),
    foreign key (event_id) references Events (id)
);

-- Recurring Event Entity Classes

create table RecurringEvents (
    event_id		serial,
    startdate 		date not null,
	enddate			date,
	ntimes 			integer,
	primary key (event_id),
    foreign key (event_id) references Events (id)
);

create table WeeklyEvents (
	id					serial,
    dayOfWeek 			DayOfWeekType not null,
	frequency			integer not null check (frequency > 0),
	primary key (id),
    foreign key (id) references RecurringEvents (event_id)
);

create table MonthlyByDayEvents (
	id					serial,
    dayOfWeek 			DayOfWeekType not null,
	weekInMonth			integer not null check (weekInMonth between 1 and 5),
	primary key (id),
    foreign key (id) references RecurringEvents (event_id)
);

create table MonthlyByDateEvents (
	id					serial,
    dateInMonth			integer not null check (dateInMonth between 1 and 31),
	primary key (id),
    foreign key (id) references RecurringEvents (event_id)
);

create table AnnualEvents (
	id					serial,
    date 				date not null,
	primary key (id),
    foreign key (id) references RecurringEvents (event_id)
);

-- Relationships

create table Member (
	user_id 			serial,
	group_id 			serial,
	primary key(user_id, group_id),
	foreign key (user_id) references Users(id),
	foreign key (group_id) references Groups(id)
);

create table subscribed (
	colour 				text,
	calendar_id 		serial,
	user_id 			serial,
	primary key (calendar_id, user_id),
	foreign key (calendar_id) references Calendars(id),
	foreign key (user_id) references Users(id)
);

create table accessibility (
	access 				AccessibilityType not null,
	calendar_id 		serial,
	user_id 			serial,
	primary key (calendar_id, user_id),
	foreign key (calendar_id) references Calendars(id),
	foreign key (user_id) references Users(id)
);

create table invited (
	status 				InviteStatus not null,
	user_id 			serial,
	event_id 			serial,
	primary key (event_id, user_id),
	foreign key (user_id) references Users(id),
	foreign key (event_id) references Events(id)
);