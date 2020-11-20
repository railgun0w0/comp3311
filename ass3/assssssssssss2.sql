-- COMP3311 20T3 Assignment 2
-- z5223796
-- Q1: students who've studied many courses

create or replace view Q1(unswid,name)
as
select  p.unswid, p.name
from   people p
join   course_enrolments ce on (ce.student = p.id)
group by p.unswid, p.name
having  count(*)> 65;

-- Q2: numbers of students, staff and both

create or replace view Q2(nstudents,nstaff,nboth)
as
SELECT(
select count(*) nstudents
from students s
left join staff st on (s.id = st.id)
where st.id is null),(

select count(*) nstaff
from students s
right join staff st on (s.id = st.id)
where s.id is null
),(
select count(*) nboth
from students s
inner join staff st on (s.id = st.id));

-- Q3: prolific Course Convenor(s)

create or replace view Q3(name,ncourses)
as
with numlist as(
select p.name, count(cs.staff) ncourses
from people p 
inner join Course_staff cs on (p.id = cs.staff)
join Staff_roles sr on (sr.id=cs.role)
where sr.name = 'Course Convenor'
group by p.name
)
select numlist.name,numlist.ncourses
from numlist
where numlist.ncourses = (select max(numlist.ncourses) from numlist);
-- Q4: Comp Sci students in 05s2 and 17s1

create or replace view Q4a(id,name)
as
select p.unswid,p.name 
from people p 
inner join Program_enrolments pe on (pe.student = p.id)
inner join Programs pro on (pe.program = pro.id)
inner join Terms tm on (pe.term = tm.id)
where pro.code like '3978' and tm.year = 2005 and tm.session = 'S2'
group by p.id,p.name
order by p.unswid;

create or replace view Q4b(id,name)
as
select p.unswid,p.name 
from people p 
inner join Program_enrolments pe on (pe.student = p.id)
inner join Programs pro on (pe.program = pro.id)
inner join Terms tm on (pe.term = tm.id)
where pro.code like '3778' and tm.year = 2017 and tm.session = 'S1'
group by p.id,p.name
order by p.unswid;


-- Q5: most "committee"d faculty

create or replace view Q5(name)
as
with numlist
as(
select facultyof(og.id) as facult, count(og.id) as num
from orgunits og
join orgunit_types ot on (ot.id = og.utype)
where facultyof(og.id) is not null and ot.name = 'Committee' 
group by facult)
select og.name from orgunits og
join numlist 
on numlist.facult = og.id
where numlist.num = (select max(num) from numlist);

-- Q6: nameOf function

create or replace function
   Q6(id integer) returns text
as $$
    select p.name
	from people p 
	where p.id = $1 OR p.unswid = $1;
$$ language sql;

-- Q7: offerings of a subject

create or replace function
   Q7(subject text)
     returns table (subject text, term text, convenor text)
as $$
   select CAST(sub.code as text),CAST(termname(terms.id) as text), p.name
   from People p
   inner join course_staff cs on(cs.staff=p.id)
   inner join courses c on(c.id = cs.course)
   inner join terms on(terms.id = c.term)
   inner join staff_roles sr on(sr.id=cs.role)
   inner join subjects sub on(sub.id = c.subject)
   where sr.name = 'Course Convenor' and sub.code = $1;
$$ language sql;

-- Q8: transcript

create or replace function
   Q8(zid integer) returns setof TranscriptRecord
as $$
declare
  record TranscriptRecord;
  uoctotal integer := 0.0;
  uocpassed integer := 0;
  wsum integer := 0;
  wam integer := 0.0;
  sid integer;
begin
  select s.id into sid
    from Students s join People p on (s.id = p.id)
    where p.unswid = $1;
    if (not found) then
      raise EXCEPTION 'Invalid student %',$1;
    end if;
    for record in
      select sub.code,
              termname(t.id),
              prog.code, 
              substr(sub.name,1,20),
              e.mark, e.grade, sub.uoc
      from People p
        join Students s on (p.id = s.id)
        join Course_enrolments e on (e.student = s.id)
        join Courses c on (c.id = e.course)
        join terms t on (c.term = t.id)
        join Subjects sub on (c.subject = sub.id)
        
      join program_enrolments pe on (pe.student = s.id) AND (pe.term = t.id) 
      join programs prog on (prog.id = pe.program) 
      where  p.unswid = $1
      order by t.starting, sub.code 
    loop
      if (record.grade in ('SY', 'XE', 'T', 'PE')) then
        uocpassed := uocpassed + record.uoc;
      elsif (record.mark is not null) then
        if (record.grade in ('PT','PC','PS','CR','DN','HD','A','B','C','XE', 'PE', 'RC', 'RS', 'T')) then
          uocpassed := uocpassed + record.uoc;
        end if;
        uoctotal := uoctotal + record.uoc;
        wsum := wsum + (record.mark * record.uoc);
        if (record.grade not in ('PT','PC','PS','CR','DN','HD','A','B','C','XE', 'PE', 'RC', 'RS', 'T')) then
          record.uoc := null;
        end if;
      else
        record.uoc := null;
      end if;
      return next record;
    end loop;
    if (uoctotal = 0) then
      record := (null,null,null,'No WAM available',null,null,null);
    else
      wam := ROUND(wsum::numeric / uoctotal::numeric);
      record := (null,null,null,'Overall WAM/UOC',wam,null,uocpassed);
    end if;
    return next record;
end;
$$ language plpgsql;

-- Q9: members of academic object group
create or replace function Q9(gid integer)
	returns setof AcObjRecord
as $$
declare
    record   AcObjRecord;
    bool        boolean;
    type        text;
    defby       text;
    def         text;
    def2        text;
    code        text;
    acode       text;
    tempstr     text;
    breakstr    text;
    tempstr2    text;
    tempstr3    text;
    bcode       text;
    firnum      integer;
    secnum      integer;
    loation     integer;
    tempstr4    text;
begin
    SELECT acad_object_groups.gtype, acad_object_groups.gdefby, acad_object_groups.definition,  acad_object_groups.negated    
    INTO  type, defby, def,bool                                                           
    FROM acad_object_groups                                                         
    WHERE acad_object_groups.id =$1;
    if (not found) then
      raise EXCEPTION 'No such group %',$1;
    end if;
    if defby != 'query' or bool = true then
        if defby = 'pattern' then
            if type = 'program' then
                for code in
                    select * from regexp_split_to_table(def, ',')
                loop
                    record := (type, code);
                    return next record;
                end loop;
            else     
                for acode in
                    select * from regexp_split_to_table(def, ',')
                loop
                    if acode like '%FREE%' or acode like '%GEN%' or acode like '%F=%' then
                        continue;
                    end if;
                    if acode like '%[%' then
                        tempstr := replace(acode,'[',',');
                        tempstr := replace(tempstr,']',',');
                        breakstr := split_part(tempstr,',',2); 
                        if breakstr similar to '%-%' then
                            firnum :=  substr(breakstr,1,1) :: integer;
                            secnum :=  substr(breakstr,3,1) :: integer;
                            for loation in firnum..secnum 
                            loop
                                tempstr4 := replace(tempstr,','||breakstr||',',loation::text);
                                for code in
                                select subjects.code
                                from subjects
                                where subjects.code similar to replace(tempstr4, '#','%')
                                loop
                                    record := (type, code);
                                    return next record;
                                end loop;
                            end loop;
                        else
                          tempstr2 := replace(tempstr,','||breakstr||',',substr(breakstr,1,1));
                          tempstr3 := replace(tempstr,','||breakstr||',',substr(breakstr,2,1));
                          for code in
                              select subjects.code
                              from subjects
                              where subjects.code similar to replace(tempstr2, '#','%') or subjects.code similar to replace(tempstr3, '#','%')  
                          loop
                              record := (type, code);
                              return next record;
                          end loop;
                        end if;
                    ELSIF acode like '%{%' then
                        tempstr := replace(acode,'{','');
                        tempstr := replace(tempstr,'}','');
                        for code in
                            select * from regexp_split_to_table(tempstr, ';')
                        loop
                            record := (type, code);
                            return next record;
                        end loop;
                    ELSIF acode like '%(%' then
                        for code in
                            select subjects.code
                            from subjects
                            where subjects.code similar to replace(acode, '#','%')
                            group by subjects.code
                        loop
                            record := (type, code);
                            return next record;
                        end loop;
                    else
                        for code in
                            select subjects.code
                            from subjects
                            where subjects.code similar to replace(acode, '#','%')  
                        loop
                            record := (type, code);
                            return next record;
                        end loop;
                    end if;
                end loop;
            end if;
        else
            if type = 'program' then
                for code in
                    select programs.code
                    from programs
                    inner join Program_group_members on (Program_group_members.program = programs.id)
                    where Program_group_members.ao_group = $1
                loop
                    record := (type, code);
                    return next record;
                end loop;
            end if;
            if type = 'stream' then
                for code in
                    select streams.code
                    from streams
                    inner join stream_group_members on (stream_group_members.stream = streams.id)
                    where stream_group_members.ao_group = $1
                loop
                    record := (type, code);
                    return next record;
                end loop;
            end if;
            if type = 'subject' then
                for code in
                    SELECT subjects.code                                            
                    FROM subjects
                    inner join subject_group_members on (subject_group_members.subject = subjects.id)
                    inner join acad_object_groups on (acad_object_groups.id = subject_group_members.ao_group)
                    where acad_object_groups.parent = $1
                Loop
                    record := (type, code);
                    return next record;
                end loop;
                for code in
                    select subjects.code
                    from subjects
                    inner join subject_group_members on (subject_group_members.subject = subjects.id)
                    where subject_group_members.ao_group = $1
                loop
                    record := (type, code);
                    return next record;
                end loop;
            end if;
        end if;
    end if;
end;
$$ language plpgsql
;
-- Q10: follow-on courses


create or replace function
   Q10(code text) returns setof text
as $$
declare
   result text;
begin
   for result in 
      select distinct sub.code from  subjects sub
      inner join  subject_prereqs sp on (sub.id = sp.subject)
      inner join  rules on (rules.id = sp.rule)
      inner join  acad_object_groups on (acad_object_groups.id = rules.ao_group)
      where acad_object_groups.definition ~ $1
   loop
      return next result;
   end loop;
end;

$$ language plpgsql;