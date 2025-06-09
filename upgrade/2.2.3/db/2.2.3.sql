use record_building


create table schema_log
(
    ID bigint NOT NULL UNIQUE,
    SCHEMA_VERSION varchar(255) NOT NULL,
    SCHEMA_TIME timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    SCHEMA_COMMENT varchar(255),
    PRIMARY KEY (ID)
);


alter table project_snapshot
    add developer_id varchar(18);

alter table build_snapshot
    add project_id bigint(15);

alter table house_snapshot
    add build_id bigint unsigned;


-- CREATE INDEX developer_idx ON project_snapshot (developer_id ASC);
CREATE INDEX work_idx ON project_snapshot (work_id,project_id ASC);

-- CREATE INDEX project_idx ON build_snapshot (project_id ASC);

CREATE INDEX work_idx ON house_snapshot (work_id,house_id ASC);
-- CREATE INDEX build_idx ON house_snapshot (build_id ASC);

CREATE INDEX work_idx ON build_snapshot (work_id,build_id ASC);

update project_snapshot s left join project p on p.project_id = s.project_id 
    set s.developer_id = p.developer_id;

update build_snapshot s left join build b on b.build_id = s.build_id
    set s.project_id = b.project_id;

update house_snapshot s left join house h on h.house_id = s.house_id   
    set s.build_id = h.build_id;


-- ----------------------------------------------------

-- ALTER TABLE build_snapshot add houses_info_id bigint NOT NULL;

-- update build_snapshot set houses_info_id = build_info_id;

-- ALTER TABLE project_snapshot add builds_info_id bigint NOT NULL;

-- update project_snapshot set builds_info_id = project_info_id;

-- CREATE TABLE build_house_snapshot
-- (
-- 	house_info_id bigint NOT NULL,
-- 	houses_info_id bigint NOT NULL,
-- 	PRIMARY KEY (house_info_id, houses_info_id)
-- ) ENGINE = InnoDB DEFAULT CHARACTER SET utf8;


-- ALTER TABLE build_house_snapshot
-- 	ADD FOREIGN KEY (house_info_id)
-- 	REFERENCES house_snapshot (house_info_id)
-- 	ON UPDATE RESTRICT
-- 	ON DELETE RESTRICT
-- ;

-- CREATE INDEX houses_info_idx ON build_house_snapshot (houses_info_id ASC);


-- INSERT INTO build_house_snapshot(house_info_id, houses_info_id)
-- SELECT 
-- s.build_info_id, h.house_info_id
-- FROM build_snapshot s
-- LEFT JOIN build_houses_snapshot h on h.diagram_id = s.diagram_id





-- CREATE TABLE project_build_snapshot
-- (
-- 	builds_info_id bigint NOT NULL,
-- 	build_info_id bigint(15) NOT NULL,
-- 	PRIMARY KEY (builds_info_id, build_info_id)
-- ) ENGINE = InnoDB DEFAULT CHARACTER SET utf8;



-- ALTER TABLE project_build_snapshot
-- 	ADD FOREIGN KEY (build_info_id)
-- 	REFERENCES build_snapshot (build_info_id)
-- 	ON UPDATE RESTRICT
-- 	ON DELETE RESTRICT
-- ;

-- CREATE INDEX builds_info_idx ON project_build_snapshot (builds_info_id ASC);

-- INSERT INTO (builds_info_id, build_info_id)
-- SELECT project_info_id, build_info_id
-- FROM project_builds_snapshot


drop table build_houses_snapshot;

drop table project_builds_snapshot;

-- 检查一下是否有 build 没有 house 记录的
-- ---------------------------------------------


alter table build drop door_number;

alter table project drop developer_name;

alter table project drop address;

alter table project_business drop info_id;

alter table build_business drop info_id;

alter table build_business add license_id bigint NULL;

alter table build_business add build_name varchar(70) NOT NULL;

alter table build_business add mapping_name varchar(38) NOT NULL;

alter table build_business add on_address varchar(256) NOT NULL;

alter table house_business drop info_id;


CREATE TABLE sale_license_info
(
	year_number int NOT NULL,
	on_number int NOT NULL,
	make_department varchar(256) NOT NULL,
	word_number varchar(16) NOT NULL,
	house_count int NOT NULL,
	house_area decimal(18,3) NOT NULL,
	house_use_area decimal(18,3) NOT NULL,
	created_at timestamp NOT NULL,
	sale_license_info_id bigint NOT NULL,
	license_number varchar(32) NOT NULL,
	PRIMARY KEY (sale_license_info_id)
) ENGINE = InnoDB DEFAULT CHARACTER SET utf8;

CREATE TABLE sale_license_work
(
	version bigint NOT NULL,
	updated_at timestamp NOT NULL,
	created_at timestamp NOT NULL,
	status varchar(16) NOT NULL,
	project_id bigint(15) NOT NULL,
	sell_object varchar(16) NOT NULL,
	valid boolean NOT NULL,
	type varchar(16) NOT NULL,
	need_fixed_price boolean NOT NULL,
	work_id bigint NOT NULL,
	PRIMARY KEY (work_id)
) ENGINE = InnoDB DEFAULT CHARACTER SET utf8;

CREATE INDEX project_status_idx ON sale_license_work (project_id ASC, status ASC);

CREATE INDEX project_idx ON sale_license_work (project_id ASC);


CREATE TABLE sale_license_destroy_work
(
	work_id bigint NOT NULL,
	project_id bigint(15) NOT NULL,
	valid boolean NOT NULL,
	version bigint NOT NULL,
	license_work bigint NOT NULL,
	PRIMARY KEY (work_id)
) ENGINE = InnoDB DEFAULT CHARACTER SET utf8;

CREATE TABLE build_completed
(
	work_id bigint NOT NULL,
	complete_year int(4) NOT NULL,
	license varchar(28) NOT NULL,
	version bigint NOT NULL,
	PRIMARY KEY (work_id)
) ENGINE = InnoDB DEFAULT CHARACTER SET utf8;



-- TODO select * from building_complete_business where not valid
INSERT INTO sale_license_work(version,updated_at,created_at,status,project_id,sell_object,valid,type,need_fixed_price,work_id) 
SELECT a.version,a.updated_at,a.created_at,a.status,a.project_id,IFNULL(a.sell_object, 'INSIDE'), IFNULL(b.valid, a.status = 'VALID') , a.type, false , a.license_id 
FROM project_sell_license a left join project_license_business b on a.license_id = b.work_id;
-- TODO 设置 need_fixed_price

INSERT INTO sale_license_info(year_number, on_number, make_department, word_number, house_count, house_area, house_use_area, created_at, sale_license_info_id,license_number)
    SELECT year_number, on_number, make_department, word_number, house_count,  house_area, house_use_area, created_at, license_id,
     concat(word_number,'房', IF(type = 'COMPLETED','竣备','销预'),'第',year_number,LPAD(on_number, 3, '0'))  FROM project_sell_license ;

INSERT INTO sale_license_destroy_work(work_id,project_id,valid,version,license_work)
SELECT work_id, project_id, valid, version, target_work_id
FROM project_license_destroy_business;

-- TODO select work_id, count(*) from project_complete_snapshot group by work_id having count(*) > 1
INSERT INTO build_completed(work_id,complete_year,license,version)
SELECT work_id,complete_year,license,1
FROM project_complete_snapshot ;


ALTER TABLE sale_license_info
	ADD FOREIGN KEY (sale_license_info_id)
	REFERENCES sale_license_work (work_id)
	ON UPDATE RESTRICT
	ON DELETE RESTRICT
;

ALTER TABLE sale_license_destroy_work
	ADD FOREIGN KEY (license_work)
	REFERENCES sale_license_work (work_id)
	ON UPDATE RESTRICT
	ON DELETE RESTRICT
;

ALTER TABLE project_complete_snapshot
	ADD FOREIGN KEY (work_id)
	REFERENCES build_completed (work_id)
	ON UPDATE RESTRICT
	ON DELETE RESTRICT
;

--  ------------------------------



alter table build_snapshot add sale_license_info_id bigint NULL;

ALTER TABLE build_snapshot
	ADD FOREIGN KEY (sale_license_info_id)
	REFERENCES sale_license_info (sale_license_info_id)
	ON UPDATE RESTRICT
	ON DELETE RESTRICT
;

--  ---------------------------
-- TODO 这个有问题 
-- update build_snapshot b left join project_sell_license l on l.project_id = b.project_id 
--     set b.sale_license_info_id = l.sale_license_info_id;

update build b left join build_snapshot bi on bi.build_info_id = b.build_info_id
    left join project_license_builds pbs on pbs.build_id = b.build_id
	set bi.sale_license_info_id = pbs.license_id 
-- TODO 历史上没有 sale license 的 A按填发时间？  B 仅填加当前的 project_license_builds ？ 

drop table project_license_builds;


drop table project_sell_license;

drop table project_license_destroy_business;

drop table project_license_business;

drop table building_complete_business;
-- ------------------


alter table project_business add district_code int NOT NULL;



alter table new_house_contract_business add register_info_id bigint;
alter table new_house_contract_business add mapping_info_id bigint;

update new_house_contract_business cb left join house_business hb on hb.work_id = cb.work_id
    set cb.register_info_id = hb.register_info_id, cb.mapping_info_id = hb.mapping_info_id;

alter table new_house_contract_business drop registration_changed;
alter table new_house_contract_business drop mapping_changed;


alter table new_house_contract_business add  contract_version int NOT NULL DEFAULT 1;

update new_house_contract_business a left join 
(select contract_id , count(*) as v , max(work_id) as work_id  
from new_house_contract_business group by contract_id,contract_version  having count(contract_id) > 1) 
b on a.contract_id = b.contract_id  and a.work_id = b.work_id 
set a.contract_version = a.contract_version + b.v - 1
where b.work_id is not null;





CREATE TABLE project_info_business
(
	work_id bigint NOT NULL,
	project_id bigint(15) NOT NULL,
	base_info_id bigint,
	construct_info_id bigint,
	land_info_id bigint,
	PRIMARY KEY (work_id, project_id)
) ENGINE = InnoDB DEFAULT CHARACTER SET utf8;

CREATE TABLE build_info_business
(
	work_id bigint NOT NULL,
	build_id bigint unsigned NOT NULL,
	construct_info_id bigint,
	location_info_id bigint,
	diagram_id bigint,
	PRIMARY KEY (work_id, build_id)
) ENGINE = InnoDB DEFAULT CHARACTER SET utf8;

CREATE TABLE house_info_business
(
	work_id bigint NOT NULL,
	house_id bigint(15) NOT NULL,
	mapping_info_id bigint,
	apartment_info_id bigint,
	apartment_diagram_id bigint,
	PRIMARY KEY (work_id, house_id)
) ENGINE = InnoDB DEFAULT CHARACTER SET utf8;

-- TODO insert house_info_business build_info_business project_info_business

alter table project_business drop base_info_id;
alter table project_business drop construct_info_id;
alter table project_business drop land_info_id;
alter table project_business drop sale_license_info_id;

alter table build_business drop construct_info_id;
alter table build_business drop location_info_id;
alter table build_business drop complete_info_id;
alter table build_business drop diagram_id;
alter table build_business drop license_id;

alter table house_business drop register_info_id;
alter table house_business drop mapping_info_id;
alter table house_business drop apartment_info_id;
alter table house_business drop apartment_diagram_id;
alter table house_business drop price_info_id;
alter table house_business drop contract_info_id;




CREATE TABLE trade_contract_info
(
	total_price decimal(19,4) NOT NULL,
	fid varchar(32),
	type varchar(12) NOT NULL,
	register_info_id bigint,
	mapping_info_id bigint,
	contract_number varchar(32) NOT NULL,
	contract_version int NOT NULL,
	work_id bigint NOT NULL,
	pricing_method varchar(16) NOT NULL,
	PRIMARY KEY (work_id),
	UNIQUE (contract_number, contract_version)
) ENGINE = InnoDB DEFAULT CHARACTER SET utf8;

CREATE UNIQUE INDEX contract_number_idx ON trade_contract_info (contract_number ASC, contract_version ASC);



insert into trade_contract_info(work_id,total_price,fid,type,
    register_info_id,mapping_info_id,contract_number,contract_version, pricing_method)
    SELECT work_id,total_price,fid,type,
    register_info_id,mapping_info_id,contract_id,contract_version,pricing_method FROM new_house_contract_business;

CREATE TABLE trade_contract_record_work
(
	work_id bigint NOT NULL,
	valid boolean NOT NULL,
	file_uploaded boolean NOT NULL,
	version bigint NOT NULL,
	house_id bigint(15) NOT NULL,
	PRIMARY KEY (work_id)
) ENGINE = InnoDB DEFAULT CHARACTER SET utf8;

CREATE INDEX house_idx ON trade_contract_record_work (house_id ASC);

insert into trade_contract_record_work(work_id,valid,file_uploaded,version, house_id)
SELECT work_id,valid,file_uploaded,version, house_id FROM new_house_contract_business;


CREATE TABLE contract_record_transferee
(
	id bigint NOT NULL AUTO_INCREMENT,
	id_type varchar(16) NOT NULL,
	id_number varchar(256) NOT NULL,
	name varchar(128) NOT NULL,
	tel varchar(32),
	work_id bigint NOT NULL,
	PRIMARY KEY (id)
) ENGINE = InnoDB DEFAULT CHARACTER SET utf8;

insert into contract_record_transferee(id_type,id_number,name,tel,work_id)
select id_type,id_number,name,tel,work_id FROM contract_business_transferee;

CREATE TABLE contract_cancel_work
(
	work_id bigint NOT NULL,
	explanation varchar(512),
	valid boolean NOT NULL,
	version bigint NOT NULL,
	contract_work bigint NOT NULL,
	PRIMARY KEY (work_id)
) ENGINE = InnoDB DEFAULT CHARACTER SET utf8;

insert into contract_cancel_work(work_id, explanation, valid, version, contract_work)
SELECT work_id, explanation, valid, version, target_work_id FROM contract_cancel_business;

alter table contract_cancel_work drop explanation;

select * from contract_cancel_work c
left join trade_contract_record_work w on w.work_id = c.contract_work
where w.work_id is null;

ALTER TABLE contract_cancel_work
	ADD FOREIGN KEY (contract_work)
	REFERENCES trade_contract_info (work_id)
	ON UPDATE RESTRICT
	ON DELETE RESTRICT
;


ALTER TABLE contract_record_transferee
	ADD FOREIGN KEY (work_id)
	REFERENCES trade_contract_info (work_id)
	ON UPDATE RESTRICT
	ON DELETE RESTRICT
;



select * from house_snapshot where house_info_id = 801048;
update house_snapshot set contract_info_id = null where house_info_id = 801048;

ALTER TABLE house_snapshot
	ADD FOREIGN KEY (contract_info_id)
	REFERENCES trade_contract_info (work_id)
	ON UPDATE RESTRICT
	ON DELETE RESTRICT
;


ALTER TABLE trade_contract_info
	ADD FOREIGN KEY (work_id)
	REFERENCES trade_contract_record_work (work_id)
	ON UPDATE RESTRICT
	ON DELETE RESTRICT
;





drop table contract_business_transferee;

drop table new_house_contract_business;

drop table contract_cancel_business;


alter table house_business add apartment_name varchar(32) NOT NULL;

update house_business b 
left join house_snapshot h on  b.before_info_id =  h.house_info_id 
left join apartment_snapshot a on a.apartment_info_id = h.apartment_info_id
set b.apartment_name = CONCAT(
        IFNULL(
            CASE
                WHEN a.unit IS NULL OR TRIM(a.unit) = '' THEN NULL
                WHEN TRIM(a.unit) REGEXP '单元$' THEN TRIM(a.unit)
                ELSE CONCAT(TRIM(a.unit), '单元')
            END,
            ''
        ),
        apartment_number
    );

alter table house add apartment_name varchar(32) NOT NULL;

update house b 
left join house_snapshot h on  b.house_info_id =  h.house_info_id 
left join apartment_snapshot a on a.apartment_info_id = h.apartment_info_id
set b.apartment_name = CONCAT(
        IFNULL(
            CASE
                WHEN a.unit IS NULL OR TRIM(a.unit) = '' THEN NULL
                WHEN TRIM(a.unit) REGEXP '单元$' THEN TRIM(a.unit)
                ELSE CONCAT(TRIM(a.unit), '单元')
            END,
            ''
        ),
        apartment_number
    );



alter table house drop mapping_corp_id;

alter table house drop mapping_corp_name;


update build set status = 'COMPLETED' WHERE status = 'COMPLETED_SALE' ;
update build set status = 'BUILDING' WHERE status = 'SALE' or status ='PREPARE' ;

-- ------------------------------------------

CREATE TABLE limits
(
	limit_info_id bigint NOT NULL,
	limit_id bigint NOT NULL,
	PRIMARY KEY (limit_info_id, limit_id)
) ENGINE = InnoDB DEFAULT CHARACTER SET utf8;



CREATE TABLE house_limit
(
	limit_id bigint NOT NULL,
	house_id bigint(15) NOT NULL,
	status varchar(8) NOT NULL,
	version bigint NOT NULL,
	PRIMARY KEY (limit_id)
) ENGINE = InnoDB DEFAULT CHARACTER SET utf8;

CREATE TABLE build_limit
(
	limit_id bigint NOT NULL,
	build_id bigint unsigned NOT NULL,
	version bigint NOT NULL,
	status varchar(8) NOT NULL,
	PRIMARY KEY (limit_id)
) ENGINE = InnoDB DEFAULT CHARACTER SET utf8;

CREATE TABLE limit_info
(
	limit_id bigint NOT NULL,
	type varchar(16) NOT NULL,
	work_id bigint NOT NULL,
	begin_at timestamp NOT NULL,
	end_at datetime NULL,
	PRIMARY KEY (limit_id)
) ENGINE = InnoDB DEFAULT CHARACTER SET utf8;


CREATE TABLE limit_create_business
(
	work_id bigint NOT NULL,
	unit varchar(8) NOT NULL,
	PRIMARY KEY (work_id)
) ENGINE = InnoDB DEFAULT CHARACTER SET utf8;


CREATE TABLE house_limit_create_work
(
	limit_id bigint NOT NULL,
	house_id bigint(15) NOT NULL,
	work_id bigint NOT NULL,
	PRIMARY KEY (limit_id)
) ENGINE = InnoDB DEFAULT CHARACTER SET utf8;

ALTER TABLE house_limit_create_work
	ADD FOREIGN KEY (work_id)
	REFERENCES limit_create_business (work_id)
	ON UPDATE RESTRICT
	ON DELETE RESTRICT
;

CREATE UNIQUE INDEX idx_house_limit ON house_limit_create_work (work_id DESC, house_id DESC);

CREATE TABLE build_limit_create_work
(
	limit_id bigint NOT NULL,
	build_id bigint unsigned NOT NULL,
	work_id bigint NOT NULL,
	PRIMARY KEY (limit_id)
) ENGINE = InnoDB DEFAULT CHARACTER SET utf8;

ALTER TABLE build_limit_create_work
	ADD FOREIGN KEY (work_id)
	REFERENCES limit_create_business (work_id)
	ON UPDATE RESTRICT
	ON DELETE RESTRICT
;

CREATE UNIQUE INDEX idx_limit_build ON build_limit_create_work (work_id DESC, build_id DESC);

CREATE TABLE limit_cancel_business_tmp
(
	work_id bigint NOT NULL,
	unit varchar(8) NOT NULL,
	PRIMARY KEY (work_id)
) ENGINE = InnoDB DEFAULT CHARACTER SET utf8;


CREATE TABLE limit_cancel_work
(
	limit_id bigint NOT NULL,
	work_id bigint NOT NULL,
	PRIMARY KEY (limit_id, work_id)
) ENGINE = InnoDB DEFAULT CHARACTER SET utf8;


CREATE TABLE freeze_business
(
	work_id bigint NOT NULL,
	version bigint NOT NULL,
	reason varchar(512) NOT NULL,
	PRIMARY KEY (work_id)
) ENGINE = InnoDB DEFAULT CHARACTER SET utf8;

CREATE TABLE freeze_cancel_business
(
	work_id bigint NOT NULL,
	reason varchar(512) NOT NULL,
	version bigint NOT NULL,
	PRIMARY KEY (work_id)
) ENGINE = InnoDB DEFAULT CHARACTER SET utf8;

insert into limit_info(limit_id, type, work_id, begin_at, end_at)
SELECT limit_id, type, work_id, limit_begin, date_to FROM sale_limit;

update limit_info set type = 'SEIZURE' WHERE type = 'SEIZURE_PREPARE' or type = 'SEIZURE_WAIT';

insert into house_limit(limit_id, house_id, status, version)
SELECT limit_id, house_id, status, version
FROM sale_limit WHERE house_id is not null;

insert into build_limit(limit_id, build_id, status, version)
SELECT limit_id, build_id, status, version
FROM sale_limit WHERE build_id is not null;

insert into limit_cancel_business_tmp(work_id, unit)
SELECT work_id, way
FROM limit_cancel_business;

insert into limit_cancel_business_tmp(work_id, unit)
SELECT work_id, way
FROM seizure_cancel_business;

insert into limit_cancel_business_tmp(work_id, unit)
SELECT work_id, way
FROM mortgage_cancel_business;



insert into limit_cancel_work(limit_id, work_id)
SELECT limit_id, work_id
FROM house_freeze_cancel_business;

insert into limit_cancel_work(limit_id, work_id)
SELECT limit_id, work_id
FROM house_seizure_cancel_business;

insert into limit_cancel_work(limit_id, work_id)
SELECT limit_id, work_id
FROM house_mortgage_cancel_business;

insert into limit_create_business(work_id, unit)
SELECT work_id, way
FROM limit_business;

insert into limit_create_business(work_id, unit)
SELECT work_id, way
FROM seizure_business;

insert into limit_create_business(work_id, unit)
SELECT work_id, way
FROM mortgage_business;

insert into house_limit_create_work(limit_id, house_id, work_id)
SELECT l.limit_id, l.target_id, l.work_id
FROM house_freeze_business l
LEFT JOIN limit_business i on i.work_id = l.work_id
WHERE i.way = 'HOUSE';

insert into house_limit_create_work(limit_id, house_id, work_id)
SELECT l.limit_id, l.target_id, l.work_id
FROM house_seizure_business l
LEFT JOIN seizure_business i on i.work_id = l.work_id
WHERE i.way = 'HOUSE';

insert into house_limit_create_work(limit_id, house_id, work_id)
SELECT l.limit_id, l.target_id, l.work_id
FROM house_mortgage_business l
LEFT JOIN mortgage_business i on i.work_id = l.work_id
WHERE i.way = 'HOUSE';

insert into build_limit_create_work(limit_id, build_id, work_id)
SELECT l.limit_id, l.target_id, l.work_id
FROM house_freeze_business l
LEFT JOIN limit_business i on i.work_id = l.work_id
WHERE i.way = 'BUILD';

insert into build_limit_create_work(limit_id, build_id, work_id)
SELECT l.limit_id, l.target_id, l.work_id
FROM house_seizure_business l
LEFT JOIN seizure_business i on i.work_id = l.work_id
WHERE i.way = 'BUILD';

insert into build_limit_create_work(limit_id, build_id, work_id)
SELECT l.limit_id, l.target_id, l.work_id
FROM house_mortgage_business l
LEFT JOIN mortgage_business i on i.work_id = l.work_id
WHERE i.way = 'BUILD';

insert into freeze_business(work_id, reason, version)
SELECT work_id, explanation, 1
FROM limit_business;

insert into freeze_cancel_business(work_id, reason, version)
SELECT work_id, explanation, 1
FROM limit_cancel_business;

alter table mortgage_business drop INDEX idk_valid_work_id;
alter table mortgage_business drop INDEX idk_work_way_from_id;
alter table mortgage_business drop INDEX idk_way_from_id;

alter table mortgage_business drop way;
alter table mortgage_business drop from_id;
alter table mortgage_business drop valid;
alter table mortgage_business add end_at datetime NOT NULL;
update mortgage_business set end_at = date_to;
alter table mortgage_business drop date_to;


alter table mortgage_cancel_business drop INDEX idk_valid_work_id;
alter table mortgage_cancel_business drop INDEX idk_work_way_from_id;
alter table mortgage_cancel_business drop INDEX idk_way_from;

alter table mortgage_cancel_business drop auto;
alter table mortgage_cancel_business drop valid;
alter table mortgage_cancel_business drop source_work_id;
alter table mortgage_cancel_business drop way;
alter table mortgage_cancel_business drop from_id;


alter table seizure_cancel_business drop INDEX idk_valid_work_id;
alter table seizure_cancel_business drop INDEX idk_work_from_id;
alter table seizure_cancel_business drop INDEX idk_way_from_id;

alter table seizure_cancel_business drop auto;
alter table seizure_cancel_business drop source_work_id;
alter table seizure_cancel_business drop way;
alter table seizure_cancel_business drop from_id;
alter table seizure_cancel_business drop valid;


alter table seizure_business drop INDEX idk_valid_work;
alter table seizure_business drop INDEX idk_wok_way_form_id;
alter table seizure_business drop INDEX idk_way_from_id;

alter table seizure_business drop from_id;
alter table seizure_business drop valid;
alter table seizure_business drop way;
alter table seizure_business add end_at datetime NOT NULL;
update seizure_business set end_at = DATE_ADD(begin_at , INTERVAL `period` DAY) WHERE period_unit = 'DAY';
update seizure_business set end_at = DATE_ADD(begin_at , INTERVAL `period` MONTH) WHERE period_unit = 'MONTH';
update seizure_business set end_at = DATE_ADD(begin_at , INTERVAL `period` YEAR) WHERE period_unit = 'YEAR';
alter table seizure_business drop `period`;
alter table seizure_business drop period_unit;


drop table sale_limit;
drop table house_freeze_business;
drop table limit_business;
drop table limit_cancel_business;
drop table house_freeze_cancel_business;
drop table house_seizure_business;
drop table house_seizure_cancel_business;
drop table house_mortgage_business;
drop table house_mortgage_cancel_business;

rename table limit_cancel_business_tmp to limit_cancel_business;

ALTER TABLE limit_cancel_work
	ADD FOREIGN KEY (work_id)
	REFERENCES limit_cancel_business (work_id)
	ON UPDATE RESTRICT
	ON DELETE RESTRICT
;


alter table house_snapshot add limit_info_id bigint;
alter table build_snapshot add limit_info_id bigint;

update house h left join house_snapshot s on s.house_info_id = h.house_info_id
 set s.limit_info_id = s.house_info_id ;

update build h left join build_snapshot s on s.build_info_id = h.build_info_id
 set s.limit_info_id = s.build_info_id;

 insert into limits(limit_info_id, limit_id)
 select h.house_info_id, l.limit_id
 FROM house h 
 LEFT JOIN house_limit l on l.house_id = h.house_id
 WHERE l.status = 'VALID';

 insert into limits(limit_info_id, limit_id)
 select b.build_info_id , l.limit_id
 FROM build b
 LEFT JOIN build_limit l on l.build_id = b.build_id
WHERE l.status = 'VALID';

alter table limit_info add explanation longtext NOT NULL;

update limit_info l left join freeze_business f on f.work_id = l.work_id 
set explanation = f.reason
WHERE l.type = 'FREEZE';

update limit_info l left join seizure_business f on f.work_id = l.work_id 
set explanation = concat('由 <storage>',  f.gov , '</storage> 执行查封')
WHERE l.type = 'SEIZURE';

update limit_info l left join mortgage_business f on f.work_id = l.work_id 
set explanation = concat('于', f.begin_at ,' 登记抵押')
WHERE l.type = 'MORTGAGE';


insert into schema_log
    (ID, SCHEMA_VERSION) values
    (1000, '2.2.3');


-- SELECT hb.build_id, hb.house_id, MAX(hb.before_info_id) AS house_info_id 
-- FROM house_business hb 
-- LEFT JOIN house_business hb_deleted ON hb.house_id = hb_deleted.house_id AND hb_deleted.work_type = 'DELETE' AND hb_deleted.before_info_id <= hb.before_info_id
-- WHERE hb_deleted.house_id IS NULL GROUP BY hb.build_id, hb.house_id;

-- SELECT hb.build_id, hb.house_id, MAX(hb.before_info_id) AS house_info_id
-- FROM house_business hb
-- WHERE hb.house_id NOT IN (
--     SELECT DISTINCT house_id 
--     FROM house_business 
--     WHERE work_type = 'DELETE' AND before_info_id <= hb.before_info_id
-- )
-- GROUP BY hb.house_id, hb.build_id;

-- SELECT hb.build_id, hb.house_id, MAX(hb.before_info_id) AS house_info_id 
-- FROM house_business hb 
-- LEFT JOIN house_business hb_deleted ON hb.house_id = hb_deleted.house_id 
-- AND hb_deleted.work_type = 'DELETE' AND hb_deleted.before_info_id <= hb.before_info_id 
-- WHERE hb_deleted.house_id IS NULL GROUP BY hb.build_id, hb.house_id;

