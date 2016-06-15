--***
create procedure inlocPretNotaDif @datajos datetime,@datasus datetime, @lm varchar(9)=null  
as 
declare @lStoehr int, @lDafora int, @lInlocPret int, @lNotaDifPret int, @lNotaDifInv int, 
	@subunitate char(9), @lunainch int, @anulinch int, @dataInch datetime, @lunabloc int, @anulbloc int, @DataBloc datetime, @dataMin datetime

set @lStoehr=isnull((select val_logica from par where tip_parametru='GE' and parametru='STOEHR'),0)
set @lInlocPret=isnull((select val_logica from par where tip_parametru='PC' and parametru='NRPARC'),0)
set @lNotaDifPret=isnull((select val_logica from par where tip_parametru='PC' and parametru='DIFPRET'),0)
set @lNotaDifInv=isnull((select val_numerica from par where tip_parametru='PC' and parametru='DIFPRET'),0)
if @lInlocPret = 0 and @lNotaDifPret = 0 -- nici Inlocuire preturi, nici Note de diferenta de pret
	return

declare @nLm int
set @nLm=(select max(lungime) from strlm where costuri=1)

set @subunitate=(select val_alfanumerica from par where tip_parametru='GE' and parametru='SUBPRO')
exec luare_date_par 'GE','LUNAINC', 0, @lunainch output, ''
exec luare_date_par 'GE','ANULINC', 0, @anulinch output, ''
exec luare_date_par 'GE','LUNABLOC', 0, @lunabloc output, ''
exec luare_date_par 'GE','ANULBLOC', 0, @anulbloc output, ''
set @DataInch=dateadd(day,-1,dateadd(month,@LunaInch,dateadd(year,@AnulInch-1901,'01/01/1901')))
set @DataBloc=dateadd(day,-1,dateadd(month,@LunaBloc,dateadd(year,@AnulBloc-1901,'01/01/1901')))
set @dataMin= (case when @dataInch<@dataBloc then @DataBloc else @dataInch end)

declare @cCont348 varchar(20), @AreAn348 int, @cContParinte348 varchar(20), @cCont711 varchar(20)
if @lNotaDifPret = 1 create table #x (cont varchar(20))

select cod,data,cod_intrare,max(pretun.pret_unitar) as pret_unitar 
into #pretPP
from pozdoc, pretun, comenzi
where pozdoc.subunitate=@subunitate and pozdoc.data between @datajos and @datasus 
and pozdoc.tip='PP' and left(pozdoc.loc_de_munca, @nLm)=pretun.loc_de_munca
and pozdoc.subunitate=comenzi.subunitate and pozdoc.comanda=comenzi.comanda
and comenzi.tip_comanda in ('P','R','C','S') and (case when @lStoehr=1 or comenzi.tip_comanda='C' then pozdoc.cod else pozdoc.comanda end)=pretun.comanda 
and pretun.data_lunii between @datajos and @datasus 
	and (@lm is null or pozdoc.loc_de_munca like @lm+'%')
-- unde @lStoehr=1 ar trebui sa fie setarea [X] Pret unitar pe cod (STOEHR)
group by cod,data,cod_intrare

declare @cBD char(100), @cPozDoc char(100), @cPozNCon char(100), @cComandaSQL char(2000) 
declare tmpbd cursor for 
	select distinct rtrim(nume_baza_de_date)+'..' from sub where @lDafora=1 
	union all 
	select '' where not exists (select 1 from sub where @lDafora=1) 

open tmpbd
fetch next from tmpbd into @cBD
while @@fetch_status=0
begin
	set @cPozDoc = RTrim(@cBD) + 'pozdoc' 
	if @lInlocPret = 1 -- Inlocuire preturi
	begin
		set @cComandaSQL='update '+RTrim(@cPozDoc)+' set pret_de_stoc=#pretPP.pret_unitar from #pretPP 
			where tip=''PP'' and subunitate='''+rtrim(@subunitate)+''' and #pretPP.cod='+RTrim(@cPozDoc)+'.cod and (exists (select 1 from '+rtrim(@cBD)+'nomencl n where n.cod=#pretPP.cod and n.tip=''F'') or #pretPP.cod_intrare='+RTrim(@cPozDoc)+'.cod_intrare) and '+RTrim(@cPozDoc)+'.data > '''+convert(char(10),@dataMin,101)+'''' 
		-- am pus sa se inlocuiasca doar in PP, de acolo se propaga prin trigger docStoc si procedurile apelate de acolo
		exec (@cComandaSQL) -- comanda poate strica corelatii de preturi, datorita TE.cod_i_primitor (pozdoc.grupa)
	end
	
	if @lNotaDifPret = 1 -- Note de diferenta de pret
	begin
		truncate table #x 
		set @cComandaSQL = 'insert into #x select val_alfanumerica from ' + RTrim(@cBD) + 'par where tip_parametru=''PC'' and parametru=''CONT348''' 
		exec (@cComandaSQL) 
		set @cCont348 = isnull((select max(cont) from #x), '') 
		if RTrim(@cCont348)='' set @cCont348='348'
		truncate table #x 
		set @cComandaSQL = 'insert into #x select convert(char(1),are_analitice) from ' + RTrim(@cBD) + 'conturi where cont=''' + @cCont348 + '''' 
		exec (@cComandaSQL) 
		set @AreAn348 = convert(int, isnull((select max(cont) from #x), '0'))
		truncate table #x 
		if @AreAn348 = 0 begin
			set @cComandaSQL = 'insert into #x select cont_parinte from ' + RTrim(@cBD) + 'conturi where cont=''' + @cCont348 + '''' 
			exec (@cComandaSQL) 
			set @cContParinte348 = isnull((select max(cont) from #x), '') 
			set @cCont711 = RTrim('711') + (case when RTrim(@cContParinte348) <> '' then substring(@cCont348, len(RTrim(@cContParinte348)) + 1, 20) else '' end) 
		end
		else begin
			set @cCont711 = RTrim('711')
		end
		set @cPozNCon = RTrim(@cBD) + 'pozncon' 
		-- stergere note 
		set @cComandaSQL = 'delete from ' + RTrim(@cPozNCon) + ' where tip=''DP'' and data between '''+convert(char(10),@datajos,101)+''' and '''+convert(char(10),@datasus,101)+'''' 
		exec (@cComandaSQL) 
		-- generare note 
		set @cComandaSQL = 'insert into ' + RTrim(@cPozNCon) + '(Subunitate, Tip, Numar, Data, Cont_debitor, Cont_creditor, Suma, 
			Valuta, Curs, Suma_valuta, Explicatii, Utilizator, Data_operarii, Ora_operarii, Nr_pozitie, Loc_munca, Comanda, Tert, Jurnal) 
			select pd.subunitate, ''DP'', pd.numar, pd.data, 
			(case when ' + (case when @lNotaDifInv=1 then '1' else '0' end) + '=1 and pu.pret_unitar - pd.pret_de_stoc < 0 
				then ''' + RTrim(@cCont711) + ''' + (case when ' + convert(char(1), @AreAn348) + '=1 and RTrim(c.cont_parinte)<>'''' then substring(pd.cont_de_stoc, len(RTrim(c.cont_parinte)) + 1, 20) else '''' end) 
				else ''' + RTrim(@cCont348) + ''' + (case when ' + convert(char(1), @AreAn348) + '=1 and RTrim(c.cont_parinte)<>'''' then substring(pd.cont_de_stoc, len(RTrim(c.cont_parinte)) + 1, 20) else '''' end)
			end), 
			(case when ' + (case when @lNotaDifInv=1 then '1' else '0' end) + '=1 and pu.pret_unitar - pd.pret_de_stoc < 0 
				then ''' + RTrim(@cCont348) + ''' + (case when ' + convert(char(1), @AreAn348) + '=1 and RTrim(c.cont_parinte)<>'''' then substring(pd.cont_de_stoc, len(RTrim(c.cont_parinte)) + 1, 20) else '''' end) 
				else ''' + RTrim(@cCont711) + ''' + (case when ' + convert(char(1), @AreAn348) + '=1 and RTrim(c.cont_parinte)<>'''' then substring(pd.cont_de_stoc, len(RTrim(c.cont_parinte)) + 1, 20) else '''' end)
			end), 
			round(convert(decimal(17,5), pd.cantitate*' + (case when @lNotaDifInv=1 then 'abs' else '' end) + '(pu.pret_unitar - pd.pret_de_stoc)), 2), 
			'''', 0, 0, ''Diferente de pret predari'', ''ASiS.PC'', getdate(), ''000000'', pd.numar_pozitie, pd.loc_de_munca, pd.comanda, '''', pd.jurnal 
			from ' + RTrim(@cPozDoc) + ' pd, #pretPP pu, conturi c
			where pd.tip=''PP'' and pd.data between '''+convert(char(10),@datajos,101)+''' and '''+convert(char(10),@datasus,101)
			+''' and pu.cod=pd.cod and pu.cod_intrare=pd.cod_intrare and pu.data=pd.data and abs(pd.pret_de_stoc - pu.pret_unitar)>=0.00001 and c.subunitate=pd.subunitate and c.cont=pd.cont_de_stoc' 
		exec (@cComandaSQL) 
	end
	fetch next from tmpbd into @cBD
end
close tmpbd
deallocate tmpbd

drop table #pretPP

if @lNotaDifPret = 1 drop table #x
