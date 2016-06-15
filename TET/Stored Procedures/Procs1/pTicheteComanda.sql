Create procedure pTicheteComanda @sesiune varchar(50), @parXML xml
as
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
set nocount on
DECLARE @eroare varchar(1000), @datajos datetime, @datasus datetime, @tipoperatie char(1), @zile_lucratoare int, 
		@tipServiciu varchar(100), @dateUnitate varchar(1000)

begin try
	select	@datajos = @parXML.value('(/*/@datajos)[1]', 'datetime'), 
			@datasus = @parXML.value('(/*/@datasus)[1]', 'datetime'), 
			@tipoperatie = @parXML.value('(/*/@tipoperatie)[1]', 'char(1)') 

	set @tipServiciu='Finisare in carnete'
	select @dateUnitate=max(case when rtrim(val_alfanumerica)<>'' and parametru='NUME' then rtrim(val_alfanumerica)+' - ' else '' end)
		+max(case when rtrim(val_alfanumerica)<>'' and parametru='LOCALIT' then 'Localitatea '+rtrim(val_alfanumerica)+' - ' else '' end)
		+max(case when rtrim(val_alfanumerica)<>'' and parametru='STRADA' then 'str '+rtrim(val_alfanumerica)+' ' else '' end)
		+max(case when rtrim(val_alfanumerica)<>'' and parametru='NUMAR' then 'nr '+rtrim(val_alfanumerica)+' ' else '' end)
		+max(case when rtrim(val_alfanumerica)<>'' and parametru='BLOC' then 'bl '+rtrim(val_alfanumerica)+' ' else '' end)
		+max(case when rtrim(val_alfanumerica)<>'' and parametru='SCARA' then 'sc '+rtrim(val_alfanumerica)+' ' else '' end)
		+max(case when rtrim(val_alfanumerica)<>'' and parametru='ETAJ' then 'etaj '+rtrim(val_alfanumerica)+' ' else '' end)
		+max(case when rtrim(val_alfanumerica)<>'' and parametru='APARTAM' then 'ap '+rtrim(val_alfanumerica)+' ' else '' end)
		+max(case when rtrim(val_alfanumerica)<>'' and parametru='JUDET' then 'jud '+rtrim(val_alfanumerica)+' ' else '' end)
		+max(case when rtrim(val_numerica)<>0 and parametru='CODPOSTAL' then 'cod postal '+rtrim(convert(char(20),val_numerica))+' ' else '' end)
		+max(case when rtrim(val_numerica)<>0 and parametru='SECTOR' then 'sector '+rtrim(convert(char(20),val_numerica))+' ' else '' end)
	from par where 
		tip_parametru='GE' and parametru in ('NUME') or tip_parametru='PS' and parametru in ('LOCALIT','STRADA','NUMAR','BLOC','SCARA','ETAJ','APARTAM','JUDET','CODPOSTAL','SECTOR')
	
	set @zile_lucratoare=isnull((select max(val_numerica) from par_lunari where tip='PS' and Parametru='ORE_LUNA' and data=@datasus),dbo.zile_lucratoare(@datajos, @datasus))

	SELECT @tipServiciu as [Serviciu finisare], @dateUnitate as [Adresa de livrare], 
		max(left(left(Nume,CHARINDEX(' ',Nume)-1),13)) as Nume, max(substring(Nume,CHARINDEX(' ',Nume)+1,30)) as Prenume, marca, cnp, 
		max(zile_lucrate) as [Nr. de zile lucrate], @zile_lucratoare/8.00 as [Nr. de zile lucratoare], 1 as [Nr. de carnete sau alte unitati de grapare], 
		sum(nr_tichete) as [Nr. de tichete], convert(decimal(12,2),valoare_unitara_tichet) as [Valoare nominala]
	FROM fTichete_de_masa (@datajos, @datasus, null, 'Tip_operatie', '1', 0, 0, @tipoperatie, null, 0, null, null, 'T', null, null, 0)
	group BY marca, cnp, convert(decimal(12,2),valoare_unitara_tichet)
			
end try
begin catch
	set @eroare=ERROR_MESSAGE()+ ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror(@eroare,16,1)
end catch

