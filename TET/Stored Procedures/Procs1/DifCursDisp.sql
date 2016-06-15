--***
create procedure DifCursDisp @parcont varchar(40),@parvaluta char(3),@datadoc datetime,@contfav varchar(40),
@contnefav varchar(40),@sterg_pl_inc_ant int,@lm char(9)='',@curs decimal(12,4)=0
/*,@contvendif varchar(40),@contcheltdif varchar(40),@ncon int*/
as
begin
	if (dbo.f_arelmfiltru(dbo.fIaUtilizator(null))=1)
	begin
			raiserror('Accesul este restrictionat pe anumite locuri de munca! Nu este permisa operatia in aceste conditii!',16,1)
			return
	end

	declare @mesaj varchar(200)
	if exists(select * from sys.objects where type='P' and name='DifCursDisp_SP')
		exec DifCursDisp_SP @parcont,@parvaluta,@datadoc,@contfav,@contnefav,@sterg_pl_inc_ant,@curs
		/*,@contvendif,@contcheltdif,@ncon*/
	else
	begin
		declare @datasus datetime,@datajos datetime,@dataincan datetime,@subunitate char(13),@aninchis int,
			@lunainchisa int,@validcomstrict int,@comandaGenerica varchar(20)

		set @subunitate=isnull((select max(val_alfanumerica) from par where tip_parametru='GE' 
			and parametru='SUBPRO'), '')
		exec luare_date_par 'GE','ANULINC',0,@aninchis output,''
		exec luare_date_par 'GE','LUNAINC',0,@lunainchisa output,''
		exec luare_date_par 'GE','COMANDA',0,@validcomstrict output,''
		exec luare_date_par 'GE','COMANDAG',0,0,@comandaGenerica output

		--set @datasus=dbo.EOM(dateadd(mm,(@anlucru-1900)* 12 + @lunalucru - 1,0) /*+ (@day-1)*/ )
		set @datasus=dbo.EOM(@datadoc)
		set @datajos=dbo.EOM(dateadd(mm,(@aninchis-1900)* 12 + @lunainchisa - 1,0)+1 /*+ (@day-1)*/ )
		--set @dataincan=dbo.BOM(dateadd(mm,(@anlucru-1900)* 12,0))
		set @dataincan=dbo.BOY(@datadoc)

		IF OBJECT_ID('tempdb..#DifCurs') IS NOT NULL drop table #DifCurs
		IF OBJECT_ID('tempdb..#DifCursFinal') IS NOT NULL drop table #DifCursFinal
-->	creez #DocDeContat pentru a o utiliza si la stergere dif. si dupa generare dif.
		IF object_id('tempdb..#DocDeContat') is not null
			drop table #DocDeContat
		else
			create table #DocDeContat (subunitate varchar(9), tip varchar(2), numar varchar(40), data datetime)

		IF OBJECT_ID('tempdb..#tmpcursuri') IS NULL
		begin
			create table #tmpcursuri (valuta varchar(20), curs float)
			insert into #tmpcursuri(valuta, curs)
			SELECT valuta, curs
			from 
				(
					SELECT 
						valuta, Curs, RANK() over (partition by valuta order by data desc) rn
					from curs
					where Data<=@datasus and valuta<>''
				) crs
			WHERE crs.rn=1
		end

		if @curs>0 and @parvaluta!=''
			update #tmpcursuri set curs=@curs where valuta=@parvaluta

		declare @user char(10) 
		set @user = isnull(dbo.fIaUtilizator(null),'')

		if @sterg_pl_inc_ant=1
		begin
			delete from pozplin 
			OUTPUT deleted.Subunitate,'PI',deleted.cont,deleted.data
			into #DocDeContat (subunitate,tip,numar,data) 
			where numar='DIF.C.V.' and left(explicatii,43)='DIFERENTE CURS LA DISPONIBIL PT. CONTURI IN' 
			and data=@datasus and (ISNULL(@parcont,'')='' or cont like rtrim(@parcont)+'%') 
			and (ISNULL(@parvaluta,'')='' or substring(explicatii,45,3)=@parvaluta)

			exec fainregistraricontabile @dinTabela=2
		end

		select c.cont, c.tip_cont, max(p.Valoare) as valuta into #conturi
			from conturi c inner join proprietati p on p.Tip='CONT' and c.Cont=p.Cod and p.cod_proprietate='INVALUTA'
		where c.cont like rtrim(@parcont)+'%' and c.subunitate=@subunitate
			group by c.cont, c.tip_cont

		select distinct a.cont,b.valuta,b.Tip_cont,isnull(c.curs,0) as curs,
		isnull((case when b.Tip_cont in ('A','B') and d.rulaj_debit>d.rulaj_credit 
		then d.rulaj_debit-d.rulaj_credit else (case when b.Tip_cont in ('P','B') 
		and d.rulaj_debit<=d.rulaj_credit then 0 else d.rulaj_debit end) end),0) as sold_debit_lei,
		isnull((case when b.Tip_cont in ('A','B') and d.rulaj_debit>d.rulaj_credit then 0 
		else (case when b.Tip_cont in ('P','B') and d.rulaj_debit<=d.rulaj_credit 
		then d.rulaj_credit-d.rulaj_debit else d.rulaj_credit end) end),0) as sold_credit_lei,
		isnull((case when b.Tip_cont in ('A','B') and e.rulaj_debit>e.rulaj_credit 
		then e.rulaj_debit-e.rulaj_credit else (case when b.Tip_cont in ('P','B') 
		and e.rulaj_debit<=e.rulaj_credit then 0 else e.rulaj_debit end) end),0) as sold_debit_valuta,
		isnull((case when b.Tip_cont in ('A','B') and e.rulaj_debit>e.rulaj_credit then 0 
		else (case when b.Tip_cont in ('P','B') and e.rulaj_debit<=e.rulaj_credit 
		then e.rulaj_credit-e.rulaj_debit else e.rulaj_credit end) end),0) as sold_credit_valuta
		into #DifCurs 
		from rulaje a 
		left outer join #conturi b on b.Cont=a.Cont
		left outer join #tmpcursuri c on c.Valuta=b.Valuta
		left outer join (select cont,valuta,sum(rulaj_debit) as rulaj_debit,SUM(rulaj_credit) as rulaj_credit 
			from rulaje where subunitate=@subunitate and data between @dataincan and @datasus and valuta='' 
			group by cont,valuta) d on a.Cont=d.Cont/* and a.Valuta=d.Valuta*/
		left outer join (select cont,valuta,sum(rulaj_debit) as rulaj_debit,SUM(rulaj_credit) as rulaj_credit 
			from rulaje where subunitate=@subunitate and data between @dataincan and @datasus and valuta<>'' 
			group by cont,valuta) e on a.Cont=e.Cont and a.Valuta=e.Valuta
		where a.subunitate=@subunitate and b.valuta<>'' and b.Valuta=a.Valuta
		and (ISNULL(@parcont,'')='' or a.cont like rtrim(@parcont)+'%') 
		and (ISNULL(@parvaluta,'')='' or b.valuta=@parvaluta) 
		and a.data between @datajos and @datasus and a.cont in (select cont from conturi where are_analitice=0 
		and sold_credit=0)
		--group by a.Cont,a.Valuta
		order by a.cont,b.valuta

		--update #DifCurs
		--set sold_debit_lei=sold_debit_lei-sold_credit_lei,sold_debit_valuta=sold_debit_valuta-sold_credit_valuta 
		--where Tip_cont='A'

		update #DifCurs
			set sold_debit_lei=sold_debit_lei-sold_credit_lei,sold_debit_valuta=sold_debit_valuta-
			sold_credit_valuta, sold_credit_lei=0, sold_credit_valuta=0
			where Tip_cont='A' or Tip_cont='B'
 
		update #DifCurs
			set sold_credit_lei=-sold_debit_lei+sold_credit_lei,sold_credit_valuta=-sold_debit_valuta+
			sold_credit_valuta, sold_debit_lei=0, sold_debit_valuta=0
			where Tip_cont='P'
 
		declare @Numar_pozitie int
		exec luare_date_par 'DO', 'POZITIE', 0, @Numar_pozitie output, ''--alocare numar pozitie
		set @Numar_pozitie=@Numar_pozitie+1
		exec setare_par 'DO', 'POZITIE', 'Ultim nr. pozitie', 0, @Numar_pozitie, ''--setare nr pozitie ca ultim nr utilizat

-->	pun in tabela temporara sumele gata calculate ca sa nu dublez conditia de where cand se scrie in #DocDeContat
		select cont,
			(case when sold_debit_valuta*curs>sold_debit_lei or sold_credit_valuta*curs<sold_credit_lei then 'ID' else 'PD' end) as tip,
			(case when sold_debit_valuta*curs>sold_debit_lei or sold_credit_valuta*curs<sold_credit_lei then @contfav else @contnefav end) as contcor,
			convert(decimal(12,2),(case when abs(sold_debit_valuta*curs-sold_debit_lei)>=0.01 then abs(sold_debit_valuta*curs-sold_debit_lei) 
				else (case when abs(sold_credit_valuta*curs-sold_credit_lei)>=0.01 then abs(sold_credit_valuta*curs-sold_credit_lei) else 0 end) end)) as suma, valuta
		into #DifCursFinal
		from #DifCurs 
		where ABS(sold_debit_valuta*curs-sold_debit_lei)>0.01 or abs(sold_credit_valuta*curs-sold_credit_lei)>0.01

		insert into pozplin (Subunitate,Cont,Data,Numar,Plata_incasare,Tert,Factura,Cont_corespondent,Suma,
		Valuta,Curs,Suma_valuta,Curs_la_valuta_facturii,TVA11,TVA22,Explicatii,Loc_de_munca,Comanda,Utilizator,
		Data_operarii,Ora_operarii,Numar_pozitie,Cont_dif,Suma_dif,Achit_fact,Jurnal)
		select @subunitate,cont,@datadoc,'DIF.C.V.',max(tip),'','',MAX(a.contcor),sum(suma),
		'',0,0,0,0,0,'DIFERENTE CURS LA DISPONIBIL PT. CONTURI IN '+max(valuta),
		@lm,(case when @validcomstrict=1 then @comandaGenerica else '' end),@user,
		convert(datetime, convert(char(10), getdate(), 104), 104), 
		RTrim(replace(convert(char(8), getdate(), 108), ':', '')),@Numar_pozitie,'',0,0,''
		from #DifCursFinal a
		group by a.cont

		delete from #DocDeContat
		insert into #DocDeContat (subunitate, tip, numar, data)
		select distinct @subunitate, 'PI', cont, @datadoc
		from #DifCursFinal d
		exec fainregistraricontabile @dinTabela=2

--		exec faInregistrariContabile @dinTabela=0, @subunitate=@subunitate, @tip='PI',@numar='DIF.C.V.', @data=@datadoc

		/*if @ncon=1
			insert into pozncon
			select @subunitate,'NC','DIF.C.V.',@datadoc,a.cont_debitor,a.cont_creditor,
			sum(a.suma),'',0,0,'DIFERENTE CURS LA DISPONIBIL PT. CONTURI IN VALUTA',@user,
			convert(datetime, convert(char(10), getdate(), 104), 104),RTrim(replace(convert(char(8), getdate(), 108), ':', '')),
			row_number() over (partition by a.cont_debitor,a.cont_creditor  order by a.cont_debitor,a.cont_creditor),'','','','DCV'
			from(
			select (case when sold_debit_valuta*curs>sold_debit_lei then @contfav else @contcheltdif end) as cont_debitor,
			(case when sold_debit_valuta*curs>sold_debit_lei then @contvendif else @contnefav end) as cont_creditor,
			(case when sold_debit_valuta*curs>sold_debit_lei then sold_debit_valuta*curs-sold_debit_lei else -(sold_debit_valuta*curs-sold_debit_lei) END) as suma
			from #DifCurs where ABS(sold_debit_valuta*curs-sold_debit_lei)>0.01 or abs(sold_credit_valuta*curs-sold_credit_lei)>0.01) a
			group by a.cont_debitor,a.cont_creditor
		*/
		return
	end
end
