--***
/*SET ANSI_NULLS ON
--GO
SET QUOTED_IDENTIFIER ON
--GO*/
--***
create procedure wOPConsultareInregContabileMF_p @sesiune varchar(50), @parXML xml 
as
begin try
	declare @sub varchar(9),@ESUnoi int,@numar varchar(20),@tip varchar(2),@subtip varchar(2),
		@data datetime,@tert varchar(20),@contcor varchar(20),@procinch float,@tipdocCG varchar(2),
		@utilizator varchar(10),@lista_lm int,@mesaj varchar(500)

	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output
	exec luare_date_par 'MF', 'ESUNOI', @ESUnoi output, 0, ''
	select @tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''),
		@subtip=ISNULL(@parXML.value('(/row/row/@subtip)[1]', 'varchar(2)'), ''),
		@numar=ISNULL(@parXML.value('(/row/row/@numar)[1]', 'varchar(20)'), ''),
		@data=ISNULL(@parXML.value('(/row/row/@data)[1]', 'datetime'), '01/01/1901'),
		@tert=ISNULL(@parXML.value('(/row/row/@tert)[1]', 'varchar(20)'), ''),
		@contcor=ISNULL(@parXML.value('(/row/row/@contcor)[1]', 'varchar(20)'), ''),
		@procinch=ISNULL(@parXML.value('(/row/row/@procinch)[1]', 'float'), 0)

	set @tipdocCG=(case when @procinch in (1,6) then 
		(case @tip when 'MI' then (case @subtip when 'AF' then 'RM' else 'AI' end) 
		when 'MM' then (case @subtip when 'EP' then 'AE' when 'FF' then 'RM' else 'AI' end) 
		when 'ME' then (case when @subtip='SU' then (case when @ESUnoi=0 or @tert='AE' then 'AE' else 'AI' end) 
			when @subtip='VI' then 'AP' else 'AE' end) 
		when 'MT' then (case when @contcor<>'' then 'AI' else '' end)  else '' end) else '' end)
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT
	set @lista_lm=0
	/*select @lista_lm=(case when cod_proprietate='LOCMUNCA' and Valoare<>'' then 1 else @lista_lm end)
		from proprietati 
		where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate in ('LOCMUNCA') and valoare<>''*/

	select right(@tip,1)+@subtip as tipdocMF,@tipdocCG as tipdocCG,convert(char(10),@data,101) as data,
		@numar as numar, CONVERT(decimal(18,2),isnull((select sum(p.Suma) 
	from pozincon p 
	where p.Subunitate=@sub and p.Tip_document=@tipdocCG and p.Numar_document=@numar and p.Data=@data 
		and p.Jurnal='MFX' and (@lista_lm=0 or exists (select 1 from proprietati lu where RTrim(p.Loc_de_munca) like RTrim(lu.valoare)+'%' 
			and lu.tip='UTILIZATOR' and lu.cod=@utilizator and lu.cod_proprietate='LOCMUNCA'))),0)) as total
	FOR XML raw, root('Date')
	
	SELECT 
	(
		select p.Tip_document tip, rtrim(p.Numar_document) numar, CONVERT(char(10),p.Data,101) data
			,rtrim(p.Cont_debitor) contdeb, rtrim(cd.Denumire_cont) dencontdeb
			,rtrim(p.Cont_creditor) contcred, rtrim(cc.Denumire_cont) dencontcred
			,CONVERT(decimal(18,2),p.Suma) suma, p.valuta, CONVERT(decimal(18,2),p.Curs) curs
			,convert(decimal(18,2),p.Suma_valuta) sumavaluta
			,RTRIM(p.Explicatii) explicatii, RTRIM(p.Loc_de_munca) lm
			,RTRIM(p.Loc_de_munca)+'-'+rtrim(lm.Denumire) denlm
			,rtrim(left(p.Comanda,20)) com, rtrim(left(p.Comanda,20))+'-'+rtrim(c.Descriere) dencom
			,isnull(substring(substring(p.Comanda,21,20),1,2),'  ')+'.'
			+isnull(substring(substring(p.Comanda,21,20),3,2),'  ')+'.'
			+isnull(substring(substring(p.Comanda,21,20),5,2),'  ')+'.'
			+isnull(substring(substring(p.Comanda,21,20),7,2),'  ')+'.'
			+isnull(substring(substring(p.Comanda,21,20),9,2),'  ')+'.'
			+isnull(substring(substring(p.Comanda,21,20),11,2),'  ')+'.'
			+isnull(substring(substring(p.Comanda,21,20),13,2),'  ') indbug
		from pozincon p
			left outer join conturi cd on p.Subunitate=cd.Subunitate and p.Cont_debitor=cd.Cont
			left outer join conturi cc on p.Subunitate=cc.Subunitate and p.Cont_creditor=cc.Cont
			left outer join lm on lm.Cod=p.Loc_de_munca
			left outer join comenzi c on c.Subunitate=p.Subunitate and c.Comanda=left(p.Comanda,20)
		where p.Subunitate=@sub and p.Tip_document=@tipdocCG and p.Numar_document=@numar 
			and p.Data=@data and p.Jurnal='MFX' 
			and (@lista_lm=0 or exists (select 1 from proprietati lu where RTrim(p.Loc_de_munca) like RTrim(lu.valoare)+'%' 
				and lu.tip='UTILIZATOR' and lu.cod=@utilizator and lu.cod_proprietate='LOCMUNCA'))
		FOR XML raw, type  
	)  
	FOR XML path('DateGrid'), root('Mesaje')
end try

begin catch
	set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch
