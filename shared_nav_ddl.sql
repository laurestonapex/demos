DROP TABLE APP_NAV_BAR;
DROP PACKAGE APP_NAV_BAR_PKG;

CREATE TABLE "APP_NAV_BAR" 
   ("NAV_BAR_PK" NUMBER GENERATED ALWAYS AS IDENTITY, 
	"NAV_BAR_FK" NUMBER, 
	"NAV_BAR_LABEL" VARCHAR2(200 BYTE), 
	"NAV_BAR_TARGET" VARCHAR2(4000 BYTE), 
	"IS_CURRENT_CONDITION" VARCHAR2(4000 BYTE), 
	"FA_ICON" VARCHAR2(100 BYTE), 
	"ATTR01" VARCHAR2(100 BYTE), 
	"ATTR02" VARCHAR2(100 BYTE), 
	"ATTR03" VARCHAR2(100 BYTE), 
	"NAV_BAR_CONDITION" VARCHAR2(4000 BYTE), 
	"CONDITION_TYPE" VARCHAR2(255 BYTE),
  "SEQ_NO" NUMBER, 
	"CREATED_BY" VARCHAR2(125 BYTE), 
	"CREATED_ON" TIMESTAMP (6), 
	"UPDATED_BY" VARCHAR2(125 BYTE), 
	"UPDATED_ON" TIMESTAMP (6), 
	"ARCHIVED" VARCHAR2(1 BYTE),
  PRIMARY KEY ("NAV_BAR_PK"),
	 CONSTRAINT "APP_NAV_BAR_FK1" FOREIGN KEY ("NAV_BAR_FK")
	  REFERENCES "APP_NAV_BAR" ("NAV_BAR_PK") ON DELETE CASCADE ENABLE
   );
   
   /
   
   create or replace package APP_NAV_BAR_PKG as

	function get_nav_bar return varchar2;

	function is_authorized(p_nav_bar_pk in number) return number;

end app_nav_bar_pkg;

/

create or replace package body APP_NAV_BAR_PKG as

---------------------------------------------------------------

--	Written By:	Laureston Solutions
-- 	Purpose:

--  Centralize the Navigation Bar between all applications.
-----------------------------------------------------------------------------

	function get_nav_bar return varchar2 is
	
---------------------------------------------------------------

--	Written By:	Laureston Solutions
--
-- 	Purpose: returns the query for the main Navigation Bar.

-- code to execute:

/* 	begin

			return app_nav_bar_pkg.get_nav_bar();
		
		end;
*/

-----------------------------------------------------------------------------
	
	l_query varchar2(4000);
	
	begin
	
		l_query:=
			'select level,'||
			'NAV_BAR_LABEL  "label",'||
			'NAV_BAR_TARGET "target" ,'||
			'''YES''  "is_current",'||
			'FA_ICON  "image",'||
			'null,'||
			'null,'||
			'attr01 attribute1,
      attr02 attribute2
			from 
			(select 
			nav_bar_pk,
			nav_bar_fk,
			nav_bar_label,
			nav_bar_target,
			fa_icon,
            attr01, 
			attr02,
      seq_no
			from APP_NAV_BAR)
			where app_nav_bar_pkg.is_authorized(nav_bar_pk) = 1
			start with nav_bar_fk is null
			connect by prior NAV_BAR_PK = NAV_BAR_FK
      order siblings by seq_no';
			
			return l_query;
		
	end get_nav_bar;
	
	function is_authorized(p_nav_bar_pk in number) return number is
	
	---------------------------------------------------------------

--	Written By:	Michelle Skamene
--
-- 	Purpose:

--  Uses the APP_NAV_BAR.SQL_CONDITION to determine if the user should see the menu
--  can use an application authorization scheme if condition_type='Authorization'
--  can use an exists query if condition_type='Exists'
-----------------------------------------------------------------------------
	
	l_return number;
	l_exists number;
	l_condition varchar2(300);
	l_nav_bar_condition varchar2(300);
	l_condition_type varchar2(100);

	
	begin
	
	  begin
		
		
		select nav_bar_condition, condition_type 
		into l_nav_bar_condition, l_condition_type
		from app_nav_bar
		where nav_bar_pk=p_nav_bar_pk;
		
		exception
			when no_data_found then
					raise_application_error (-20000,
					'P_NAV_BAR_PK is not valid in app_nav_bar_pkg.has_access');    

		end;

		 
		if l_nav_bar_condition is null then  -- no condition on the menu, display
				l_return:=1;
		elsif l_condition_type='Authorization' then
				if apex_authorization.is_authorized(p_authorization_name=>l_nav_bar_condition) then
							l_return:=1;
				else
							l_return:=0;
				end if;

		elsif l_condition_type='Exists' then
		
				begin
							
					execute immediate l_nav_bar_condition into l_exists;
					l_return:=1;
								
				exception 
					when no_data_found then -- the condition is not met
							l_return:=0;
					when too_many_rows then -- the condition is met
							l_return:=1;
					when others then -- a poorly written query? Let's just say no access
							l_return:=0;
				end; 
									
			else
			  l_return:=0;  -- we will build on other options here
			end if;
			
		
		return l_return;

	end is_authorized;

end app_nav_bar_pkg;