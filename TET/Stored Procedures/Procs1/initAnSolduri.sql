--***
create procedure initAnSolduri @sesiune varchar(50)='', @an int
as
begin
declare @eroare varchar(2000)
begin try
	declare @utilizator varchar(20)
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output

	if (dbo.f_arelmfiltru(@utilizator)=1)
		raiserror('Accesul este restrictionat pe anumite locuri de munca! Nu este permisa initializarea rulajelor in aceste conditii!',16,1)

	declare @data datetime, @dataInit datetime, @rulajelm bit
	select @rulajelm=isnull((select top 1 val_logica from par where Parametru='RULAJELM'),0)

	select	@data=convert(varchar(20),@an-1)+'-12-31',
			@dataInit=convert(varchar(20),@an)+'-1-1'

	delete rulaje where data=@dataInit

	insert into rulaje(Subunitate, Cont, Loc_de_munca, Valuta, Data, Rulaj_debit, Rulaj_credit)
	select Subunitate, Cont, (case when @rulajelm=1 then isnull(Loc_de_munca,'') else '' end), Valuta, @dataInit, sum(debit), sum(credit)
	from fCalculSolduri(@data) where debit<>0 or credit<>0
	group by subunitate, cont, (case when @rulajelm=1 then isnull(Loc_de_munca,'') else '' end), Valuta
end try
begin catch
	set @eroare=ERROR_MESSAGE()+' (initAnSolduri '+convert(varchar(20),ERROR_LINE())+')'
end catch
if len(@eroare)>0 raiserror(@eroare, 16,1)
end
