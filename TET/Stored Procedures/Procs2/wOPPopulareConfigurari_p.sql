--***
create procedure wOPPopulareConfigurari_p(@sesiune varchar(50)=null,
		@parXML xml=null)
as
	select 2 as publicabil, 2 as farastd for xml raw
