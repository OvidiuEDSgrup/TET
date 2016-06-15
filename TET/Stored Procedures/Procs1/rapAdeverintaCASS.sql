/**
	Procedura este folosita pentru a lista Adeverinte pentru CASS (casa de sanatate). 
**/
create procedure rapAdeverintaCASS (@sesiune varchar(50), @marca varchar(6), @datajos datetime, @datasus datetime, @dataset char(2), @parXML xml='<row/>')
AS
/*
	exec rapAdeverintaCASS '', '1', '01/01/2012', '12/31/2012', 'P', '<row />'
*/
begin try 
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @sub varchar(9), @denunit VARCHAR(100), @adrunit VARCHAR(100), @codfisc VARCHAR(100), @ordreg VARCHAR(100), @caen VARCHAR(100), @judet VARCHAR(100), @localit varchar(100), @contbanca VARCHAR(100), 
		@banca varchar(100), @dirgen varchar(100), @direc varchar(100), @sefpers varchar(100), @telefon varchar(100), @email varchar(100), 
		@compartiment varchar(100), @functierepr varchar(100), @numerepr varchar(100), @numec varchar(100), @functc varchar(100), 
		@tip varchar(2), @mesaj varchar(1000), @cTextSelect nvarchar(max), @debug bit, 
		@utilizator varchar(50), @lista_lm int, @data_12 datetime, @userWindows varchar(50), @doRevert bit

	if @sesiune<>''
		exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
	else 
		set @utilizator=dbo.fIaUtilizator(null)

	set @lista_lm=dbo.f_areLMFiltru(@utilizator)
	
	select @userWindows=RTRIM(u.observatii)
	from asisria..sesiuniRIA s, utilizatori u 
	where s.token=@sesiune and u.ID=s.utilizator

	if @userWindows <> SUSER_NAME() and LEN(isnull(@userWindows,''))>0
	begin
		exec as login = @userWindows
		set @doRevert=1
	end

	/**
		Informatiile din PAR sau similare se iau o singura data, nu in selectul principal care ar cauza rularea instructiunilor de multe ori
	*/
	select	@sub=(case when parametru='SUBPRO' then rtrim(val_alfanumerica) else @sub end),
			@denunit=(case when parametru='NUME' then rtrim(val_alfanumerica) else @denunit end),
			@codfisc=(case when parametru='CODFISC' then rtrim(val_alfanumerica) else @codfisc end),
			@ordreg=(case when parametru='ORDREG' then rtrim(val_alfanumerica) else @ordreg end),
			@caen=(case when parametru='CAEN' then rtrim(val_alfanumerica) else @ordreg end),
			@judet=(case when parametru='JUDET' then rtrim(val_alfanumerica) else @judet end),
			@localit=(case when parametru='SEDIU' then rtrim(val_alfanumerica) else @localit end),
			@adrunit=(case when parametru='ADRESA' then rtrim(val_alfanumerica) else @adrunit end),
			@contBanca=(case when parametru='CONTBC' then rtrim(val_alfanumerica) else @contBanca end),
			@banca=(case when parametru='BANCA' then rtrim(val_alfanumerica) else @banca end),
			@dirgen=(case when parametru='DIRGEN' then rtrim(val_alfanumerica) else @dirgen end),
			@direc=(case when parametru='DIREC' then rtrim(val_alfanumerica) else @direc end),
			@sefpers=(case when parametru='DIREC' then rtrim(val_alfanumerica) else @sefpers end),
			@telefon=(case when parametru='TELFAX' then rtrim(val_alfanumerica) else @telefon end),
			@email=(case when parametru='EMAIL' then rtrim(val_alfanumerica) else @email end),
			@compartiment=(case when parametru='COMP' then rtrim(val_alfanumerica) else @compartiment end),
			@functierepr=(case when parametru='FDIRGEN' then rtrim(val_alfanumerica) else @functierepr end),
			@numerepr=(case when parametru='DIRGEN' then rtrim(val_alfanumerica) else @numerepr end),
			@numec=(case when parametru='DIREC' then rtrim(val_alfanumerica) else @numec end),
			@functc=(case when parametru='FDIREC' then rtrim(val_alfanumerica) else @functc end)
	from par
	where Tip_parametru='GE' and Parametru in ('SUBPRO','NUME','CODFISC','ORDREG','ADRESA','JUDET','SEDIU','CONTBC','BANCA','FDIRGEN','DIRGEN','FDIREC','DIREC','SEFPERS','TELFAX','EMAIL') 
		or Tip_parametru='PS' and Parametru in ('CAEN','COMP')

	declare @lunaInch int, @anulInch int, @dataInch datetime, @dataPI datetime
	set @lunaInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='LUNA-INCH'), 1)
	set @anulInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='ANUL-INCH'), 1901)

	set @data_12=dbo.BOM(DateADD(month,-12,@datajos))
--	date salariat
	if @dataset='S'	
	begin
		select p.nume, p.cnp, p.tip_act, p.serie_bul, p.nr_bul, p.elib, p.data_elib, p.data_angajarii, p.Localitate, p.adresa, p.judet, 
		(case when p.data_angajarii>@data_12 then rtrim(convert(char(3),DateDiff(month,p.Data_angajarii,@datasus)+1)) else '12' end)+' luni' as nrluni
		from fDateSalariati (@marca, @datasus) p	
	end

--	date concedii medicale
	if @dataset='CM' and 1=0
	begin
		declare @cHostID varchar(8)
		set @cHostID=isnull((select convert(char(8), abs(convert(int, host_id())))),'')
		
		delete from avnefac where terminal=@cHostid 
		-- folosim isnull pentru formulare cu procedura, la care nu avem nevoie de avnefac.
		insert into avnefac(Terminal,Subunitate,Tip,Numar,Cod_gestiune,Data,Cod_tert,
		Factura,Contractul, Data_facturii,Loc_munca,Comanda,Gestiune_primitoare,Valuta,Curs,Valoare,Valoare_valuta,Tva_11,Tva_22, 
		Cont_beneficiar,Discount) 
		values (@cHostID,@Sub,'AD',@marca,'',dbo.eom(@datasus), convert(char(10),@datasus,101), '', '', @data_12,'','','','',0,12,0,0,0,'',0) 

		select marca, luna, an, zile_cm, total_zile_cm, zile_calend_cm, total_zile_calend_cm 
		from dbo.fFormAdeverintaCassCM()	
	end

--	date concedii medicale pe perioade
	if @dataset='CM'
	begin
		select data, dbo.fDenumireLuna(cm.Data) as luna, year(cm.data) as an, dbo.fDenumireLuna(cm.data)+' - '+convert(char(4),year(cm.data)) as perioada, marca,
			convert(char(10),data_inceput,103) as data_inceput, convert(char(10),data_sfarsit,103) as data_sfarsit,
			(case when right(cm.tip_diagnostic,1)='-' then '0'+left(cm.tip_diagnostic,1) else cm.tip_diagnostic end)+' - '+rtrim(d.denumire) as tip_concediu,
			cm.zile_lucratoare as zile_cm, DATEDIFF(day,cm.Data_inceput,cm.Data_sfarsit)+1 as zile_calend_cm, 
			isnull((select sum(cm1.zile_lucratoare) from conmed cm1
				where cm1.marca=cm.marca and cm1.data>=@data_12 and cm1.data<=@dataSus and cm1.Tip_diagnostic not in ('0-','8-','9-')),0) as total_zile_cm,
			isnull((select sum(DATEDIFF(day,cm1.Data_inceput,cm1.Data_sfarsit)+1) from conmed cm1 
				where cm1.marca=cm.marca and cm1.data>=@data_12 and cm1.data<=@dataSus and cm1.Tip_diagnostic not in ('0-','8-','9-')),0) as total_zile_calend_cm
		from conmed cm
			left outer join fDiagnostic_CM() d on d.Tip_diagnostic=cm.Tip_diagnostic
		where cm.marca=@marca and cm.data between @data_12 and @dataSus and cm.Tip_diagnostic not in ('0-','8-','9-')
	end

	if @dataset='PI' --	persoane in intretinere
	begin
		set @dataInch=dateadd(month,1,convert(datetime,str(@lunaInch,2)+'/01/'+str(@anulInch,4)))
		set @dataPI=dbo.EOM(case when @datasus<@dataInch then @datasus else @dataInch end)

		select ROW_NUMBER() OVER(ORDER BY p.nume_pren DESC) as nr_crt, nume_pren, cod_personal from persintr p 
		where marca=@marca and data=@dataPI and p.Coef_ded=1 and p.Tip_intretinut not in ('C','U','A')	
	end

end try
begin catch
	set @mesaj=ERROR_MESSAGE()+ ' (rapAdeverintaCASS)'
	raiserror(@mesaj, 11, 1)
end catch

if @doRevert=1
	revert
