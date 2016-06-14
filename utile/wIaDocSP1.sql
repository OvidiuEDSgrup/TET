if exists (select * from sysobjects where name ='wIaDocSP1')
	drop procedure wIaDocSP1
go

create procedure wIaDocSP1 @sesiune varchar(50), @parXML xml output
as
declare @eroare varchar(2000)
select @eroare=''
begin try
	set transaction isolation level read uncommitted
	--declare @filtrareSP int
	--select @filtrareSP=0
	declare @tip varchar(20), @f_tert varchar(50), @f_contract varchar(50), @f_data_jos datetime, @f_data_sus datetime 

	set @tip = @parXML.value('(/row/@tip)[1]', 'varchar(2)') 

	if @tip='AP' and @parxml.value('(row/@info6)[1]','varchar(50)') is not null
	begin

		select	@f_tert = isnull(@parXML.value('(/row/@tert)[1]', 'varchar(50)'), ''),
				@f_contract = isnull(@parXML.value('(/row/@numar)[1]', 'varchar(50)'), ''),
				@f_data_jos = ISNULL(@parXML.value('(/row/@datajos)[1]', 'datetime'),'01/01/1901'),
				@f_data_sus = ISNULL(@parXML.value('(/row/@datasus)[1]', 'datetime'),'12/31/2999')
			
		select @f_data_jos=dateadd(d,-1,	dateadd(m,1,		--> data implementarii
			isnull((select convert(varchar(4),val_numerica) from par where tip_parametru='ge' and parametru='ANULIMPL'),'1921')+'-'+
			isnull((select convert(varchar(2),val_numerica) from par where tip_parametru='ge' and parametru='lunaimpl'),'1')+'-1'
			))
			, @f_data_sus='2100-12-31'

		SET @parxml.modify('delete  (/row/@numar)[1]')
		SET @parxml.modify('delete  (/row/@data)[1]')

		set @parXML.modify('replace value of (/row/@datajos)[1] with sql:variable("@f_data_jos")') 
		set @parXML.modify('replace value of (/row/@datasus)[1] with sql:variable("@f_data_sus")') 

		if @parXML.value('(/row/@f_contract)[1]', 'varchar(2)') is not null                          
			set @parXML.modify('replace value of (/row/@f_contract)[1] with sql:variable("@f_contract")') 
		else
			set @parXML.modify ('insert attribute f_contract {sql:variable("@f_contract")} into (/row)[1]')
	end
	
	if @tip='TE' and @parxml.value('(row/@info6)[1]','varchar(50)') is not null
	begin

		select	--@f_tert = isnull(@parXML.value('(/row/@tert)[1]', 'varchar(50)'), ''),
				@f_contract = isnull(@parXML.value('(/row/@numar)[1]', 'varchar(50)'), ''),
				@f_data_jos = ISNULL(@parXML.value('(/row/@datajos)[1]', 'datetime'),'01/01/1901'),
				@f_data_sus = ISNULL(@parXML.value('(/row/@datasus)[1]', 'datetime'),'12/31/2999')
			
		select @f_data_jos=dateadd(d,-1,	dateadd(m,1,		--> data implementarii
			isnull((select convert(varchar(4),val_numerica) from par where tip_parametru='ge' and parametru='ANULIMPL'),'1921')+'-'+
			isnull((select convert(varchar(2),val_numerica) from par where tip_parametru='ge' and parametru='lunaimpl'),'1')+'-1'
			))
			, @f_data_sus='2100-12-31'

		SET @parxml.modify('delete  (/row/@numar)[1]')
		SET @parxml.modify('delete  (/row/@data)[1]')

		set @parXML.modify('replace value of (/row/@datajos)[1] with sql:variable("@f_data_jos")') 
		set @parXML.modify('replace value of (/row/@datasus)[1] with sql:variable("@f_data_sus")') 

		if @parXML.value('(/row/@f_contract)[1]', 'varchar(2)') is not null                          
			set @parXML.modify('replace value of (/row/@f_factura)[1] with sql:variable("@f_contract")') 
		else
			set @parXML.modify ('insert attribute f_factura {sql:variable("@f_contract")} into (/row)[1]')
	end

end try
begin catch
	set @eroare =ERROR_MESSAGE()+' (wIaDocSP1)'
	if len(@eroare)>0 raiserror(@eroare,16,1)
end catch

