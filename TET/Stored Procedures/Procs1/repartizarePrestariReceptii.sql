--***
create procedure repartizarePrestariReceptii @tip varchar(2), @numar char(20), @data datetime
as
begin try
	declare @total_prestare float,@total_asycuda float, @Cod_prest varchar(20)
	declare @Sb char(9),@CodPS int,@RPGreu int,@NrPozitie int,@SumaTVA float, @DVE int,@Utilizator char(10),@CNEEXREC varchar(40),
			@ACTNOMINT int

	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Sb output -->subunitate
	exec luare_date_par 'GE', 'CODPS', @CodPS output, 0, '' -->Cod intrare = pret de stoc
	exec luare_date_par 'GE', 'RPGREU', @RPGreu output, 0, ''-->Repartizare prestari pe greutate
	exec luare_date_par 'GE', 'ACTNOMINT', @ACTNOMINT output, 0, ''-->Act. nomenclator la operare documente

	IF OBJECT_ID('tempdb..#pozitiiRM') IS NOT NULL
		DROP TABLE #pozitiiRM
		
	--preluam intr-o tabela temporara pozitiile receptiei
	select p.idPozDoc,p.subunitate,p.numar,p.data, p.tip, p.numar_DVI, 
		isnull(p.detalii.value('(/*/@taxe_vama)[1]','float'),p.TVA_deductibil) as taxe_vama, p.suprataxe_vama as comision_vamal, 
		p.Pret_vanzare,p.pret_de_stoc,p.Pret_valuta,p.Discount,p.Valuta,p.Curs,n.Greutate_specifica,p.numar_pozitie,p.cantitate,p.cod,
		p.Pret_valuta*(1+p.Discount/100)*(case when isnull(p.Valuta,'')<>'' then p.Curs else 1 end) as pret_stoc_anterior,--pret stoc inainte de DVI si prestari	
		p.Pret_valuta*(1+p.Discount/100)*(case when isnull(p.Valuta,'')<>'' then p.Curs else 1 end) as pret_stoc_anteriorDVI,--pret stoc dupa DVI, inainte de prestari
		p.Accize_datorate,
		p.Pret_valuta*(1+p.Discount/100)*(case when isnull(p.Valuta,'')<>'' then p.Curs else 1 end) as pret_stoc_anteriorDVIcuPrestCoduri, --pret stoc dupa repartizarea prestarilor pe cod	
		p.Pret_valuta*(1+p.Discount/100)*(case when isnull(p.Valuta,'')<>'' then p.Curs else 1 end) as pret_stoc_final--pret stoc final(DVI+prestari cu coduri+prestari fara coduri)
	into #pozitiiRM
	from pozdoc p, nomencl n
	where p.Subunitate=@Sb
		and p.Numar=@Numar
		and p.Data=@Data
		and p.cod=n.cod
		and p.Tip='RM'
		and p.Cantitate*p.Pret_valuta*(1+p.Discount/100)*(case when isnull(p.Valuta,'')<>'' then p.Curs else 1 end)>0

	update #pozitiiRM
		set taxe_vama=0, comision_vamal=0 where numar_dvi=''

	--stergem prestarile pe coduri care nu mai sunt in receptie
	delete pozdoc 
	where Subunitate=@Sb
		and Numar=@Numar
		and Data=@Data
		and tip in ('RP','RZ')
		and isnull(cod,'')<>''
		and not exists(select 1 from #pozitiiRM p where p.cod=pozdoc.cod )		 	


	--DVI
	--daca a fost introdus DVI pe receptie, se modifica pretul de stoc pe pozitiile care au numar dvi completat
		--se presupune ca in campul pozdoc.taxe_vama exista deja suma din taxele vamale corspunzatoare pozitiei(repartizarea asta se face in momentul operarii DVI in proc wOPDVI)
	update #pozitiiRM
		set pret_stoc_anteriorDVI=pret_stoc_anterior+(Pret_vanzare/Cantitate)+((taxe_vama+comision_vamal)/Cantitate),
			pret_stoc_anteriorDVIcuPrestCoduri=pret_stoc_anterior+(Pret_vanzare/Cantitate)+((taxe_vama+comision_vamal)/Cantitate),
			pret_stoc_final=pret_stoc_anterior+(Pret_vanzare/Cantitate)+((taxe_vama+comision_vamal)/Cantitate)
	where isnull(Numar_DVI,'')<>''	
	
	IF OBJECT_ID('tempdb..#calcul_prestari') IS NOT NULL
	DROP TABLE #calcul_prestari
	
	--calcul sume ce urmeaza a fi repartizate pe fiecare cod in parte
	select 
		idPozDoc,
		subunitate,
		numar,
		data,
		isnull(cod,'') as cod, 
		dbo.rot_val(cantitate*pret_valuta,2) as valDeRepartizat,
		--dbo.rot_val(suprataxe_vama,2) as valAsycuda,
		isnull(detalii.value('(/row/@rep_greutate)[1]','char(1)'),isnull(nullif(accize_datorate,0),@RPGreu)) as tipRepartizarePrestari /*1 - Greutate, 0 - Altfel*/
	into #calcul_prestari
	from pozdoc 
	where subunitate=@Sb 
		and tip in ('RP', 'RZ') 
		and gestiune_primitoare='' 
		and numar=@numar 
		and data=@data 
	order by idPozDoc

	alter table #calcul_prestari
		add	valRMFaraTaxe float, 
		greutateRM float

	create table #rezultatFinal (idPozDoc int,idPozDocPrestare int,valoare float)
	
	/*
		Se va face o repartizare a prestarii in bucla. Linie cu linie. Ne va ajuta si la calculul notei contabile pe linii
	*/
	--calcul valori totale pe receptie, necesare pentru repartizarea receptiilor --acum doar pentru prestari pe coduri
	update c set valRMFaraTaxe=r.valRMFaraTaxe, greutateRM=r.greutateRM
	from #calcul_prestari c
		outer apply (
			select sum(p.Cantitate*p.pret_stoc_anteriorDVIcuPrestCoduri) as valRMFaraTaxe,
				sum(p.Cantitate*(case when n.Greutate_specifica=0 and n.um='T' then 1000 when n.Greutate_specifica=0 and n.um='KG' then 1 else n.Greutate_specifica end)) as greutateRM,
				sum(p.Cantitate) as cantRM,
				SUM(accize_datorate) as valComisionRM
			from #pozitiiRM p 
				left outer join nomencl n on p.cod=n.cod
			where isnull(c.cod,'')='' or p.cod=c.cod
			) r	

	delete rp 
	from RepartizarePrestari rp
	inner join #calcul_prestari c on rp.idPozPrestare=c.idPozDoc

	declare @idPozdocPrestare int
	set @idPozdocPrestare=0
	select top 1 @idPozdocPrestare=idPozDoc
		from #calcul_prestari
	
	/*
		Pentru fiecare prestare punem rezultatul intr-o tabela temporara pentru a putea face corect notele contabile.
		Si pentru a nu merge chiar babeste
	*/
	while @idPozdocPrestare>0
	begin

		insert into #rezultatFinal
		select p.idPozDoc,c.idPozDoc,
			(case when c.tipRepartizarePrestari=1 /*'Greutate'*/ then
				round(((p.Greutate_specifica*p.Cantitate*100)/c.greutateRM)*c.valDeRepartizat/100,5)
			else
				round(p.cantitate*(p.pret_stoc_anteriorDVI*c.valDeRepartizat/c.valRMFaraTaxe),5)
			end)
		from #pozitiiRM p,#calcul_prestari c
		where c.idPozDoc=@idPozdocPrestare and (isnull(c.cod,'')='' or c.cod=p.cod)
		and abs((case when c.tipRepartizarePrestari=1 /*'Greutate'*/ then c.greutateRM else c.valRMFaraTaxe end))>0.00001
	
		delete from #calcul_prestari where idPozDoc=@idPozDocPrestare
		set @idPozdocPrestare=0
		select top 1 @idPozdocPrestare=idPozDoc
			from #calcul_prestari
	end
	
	insert into RepartizarePrestari(idPozDoc,idPozPrestare,suma)
	select idPozDoc,idPozDocPrestare,valoare
	from #rezultatFinal where abs(valoare)>0.00001

	/*La final scriem rezultatul final in pozdoc*/
	update pd set Pret_de_stoc=pdCalc.newPStoc,Accize_datorate=pdCalc.difVal
	/*Se calculau si accize datorate. De vazut daca mai trebuie*/
	from pozdoc pd
	inner join 
		(select p.idPozDoc,convert(decimal(17,5),(p.cantitate*p.pret_stoc_anteriorDVIcuPrestCoduri+sum(isnull(r.valoare,0)))/p.cantitate) as newPStoc,
		sum(isnull(r.valoare,0)) as difVal --Compatibilitate in urma. Noile proceduri nu se vor lega de acest camp ci de tabela RepartizarePrestari
		from #pozitiiRM  p 
		left outer join #rezultatFinal r on p.idPozDoc=r.idPozDoc
		group by p.idPozDoc,p.pret_stoc_anteriorDVIcuPrestCoduri,p.cantitate) pdCalc on pd.idPozDoc=pdCalc.idPozDoc


	--apelare procedura pentru completarea valorii de inventar a mijloacelor fixe dupa recalcularea pretului de stoc
	if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuMFdinCG') 
		and exists (select 1 from pozdoc where Subunitate=@sb and Tip='RM' and Numar=@numar and Data=@data and subtip='MF')
	begin
		declare @p2 xml
		set @p2=(select 'RM' as '@tip', @numar as '@numar', @data as '@data', (select 1 as '@update', 'MF' as '@subtip' for XML path,type) for XML path,type)
		exec wScriuMFdinCG '', @p2
	end
	
	exec refaceredoc @dataj=@data, @datas=@data, @tip='RM', @numar=@numar	

 end try
 begin catch
	declare @eroare varchar(max) 
	set @eroare=ERROR_MESSAGE() + ' (repartizarePrestariReceptii)'
	raiserror(@eroare, 16, 1) 
 end catch
