--***
Create function fRaportareCMFnuass 
	(@datajos datetime, @datasus datetime, @marca char(6)=null, @locm varchar(9)=null, @codboala char(2), @cTip_diagnostic_exceptat char(2), @medicale_incap_temp int, @inderulare int) 
returns @concedii_medicale table
	(Nume char(50), cnp char(13), medic char(50), unitate char(50), tip_diagnostic char(2), denumire char(30), data_inceput datetime, data_sfarsit datetime)
as
begin
	declare @utilizator varchar(20)  -- pt filtrare pe proprietatea LOCMUNCA a utilizatorului (daca e definita)
	set @utilizator = dbo.fIaUtilizator(null)

	insert @concedii_medicale 
	select p.Nume, p.cod_numeric_personal, b.Medic_prescriptor, b.unitate_sanitara, c.tip_diagnostic, d.denumire, c.data_inceput, c.data_sfarsit
	from personal p
		inner join infoconmed b on b.Marca=p.marca
		left outer join conmed c on c.Data=b.Data and c.marca=b.Marca and c.Data_inceput=b.Data_inceput
		left outer join dbo.fDiagnostic_CM() d on d.tip_diagnostic=c.tip_diagnostic
	where b.Data_inceput between @datajos and @datasus
		and (isnull(@marca,'')='' or p.Marca=@marca)
		and (isnull(@locm,'')='' or p.Loc_de_munca like rtrim(@locm)+'%')
		and (isnull(@codboala,'')='' or c.tip_diagnostic=@codboala)
		and (isnull(@cTip_diagnostic_exceptat,'')='' or c.tip_diagnostic<>@cTip_diagnostic_exceptat)
		and	(@medicale_incap_temp=0 or (@medicale_incap_temp=1 and c.tip_diagnostic in ('1-','2-','5-','6-','12','13','14'))) 
		and	(@inderulare=0 or (@inderulare=1 and getdate() between @datajos and @datasus)) 
		and c.tip_diagnostic between '1-' and '9-'
		and (dbo.f_areLMFiltru(@utilizator)=0 or exists (select 1 from lmfiltrare l where l.utilizator=@utilizator and l.cod=p.Loc_de_munca))

	return
end
