create procedure  [dbo].[wIaPlanBugetar] @sesiune varchar(50), @parXML XML    
as 
begin try  
	set transaction isolation level READ UNCOMMITTED

	Declare  
		@gestiune varchar(20),@gestutiliz varchar(20), @categoriePret int, @cSub char(9), @utilizator varchar(20),@filtruCod_de_Bare varchar(80) ,
		@filtruAn varchar (100),@indbug varchar(20),@anfiltru int,@mesajeroare varchar(500),@filtrulm varchar(80)
 
	select @indbug = @parXML.value('(/row/@indbug)[1]','varchar(20)'),
			@filtrulm = isnull(@parXML.value('(/row/@filtrulm)[1]','varchar(80)'),'')
	
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT
	
	declare @anchar varchar(10)
	set @anchar=isnull(@parXML.value('(/row/@anplan)[1]','varchar(10)'),'')
	if isnumeric(@anchar)=1
		set @anfiltru=convert(int,@anchar)
	else 
		set @anfiltru=year(getdate())

	declare @lista_lm int
	set @lista_lm=(case when exists (select 1 from proprietati 
	where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate='LOCMUNCA' and Valoare<>'') then 1 else 0 end)

	select top 100 
		RTRIM(p.loc_munca) as lm, rtrim(lm.denumire) as denlm, 
		sum(case when DATEPART(QUARTER,Data)=1 then convert(decimal(12,3),p.suma) else 0 end) as suma1,
		sum(case when DATEPART(QUARTER,Data)=2 then convert(decimal(12,3),p.suma) else 0 end) as suma2,
		sum(case when DATEPART(QUARTER,Data)=3 then convert(decimal(12,3),p.suma) else 0 end) as suma3,
		sum(case when DATEPART(QUARTER,Data)=4 then convert(decimal(12,3),p.suma) else 0 end) as suma4
	from pozncon p  
		left join lm on lm.cod=p.loc_munca
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and p.Loc_munca=lu.cod
	where p.tip='AO'
		and left(p.numar,2)='BA' 
		and year(p.data)=@anfiltru
		and substring(p.comanda,21,20)=@indbug 
		and (@lista_lm=0 or lu.cod is not null)
		and (p.Loc_munca=@filtrulm or isnull(@filtrulm,'')='')
	group by RTRIM(p.loc_munca), rtrim(lm.denumire)
	--order by 1
	for xml raw    
end try
begin catch
	set @mesajeroare=ERROR_MESSAGE()
	raiserror(@mesajeroare,11,1)
end catch
