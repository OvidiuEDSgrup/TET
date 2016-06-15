
CREATE procedure wmProceseazaIncasare @sesiune varchar(50), @parXML xml
as
if exists(select * from sysobjects where name='wmProceseazaIncasareSP' and type='P')
begin
	exec wmProceseazaIncasareSP @sesiune, @parXML 
	return 0
end
begin try
	declare
		@tabel xml, @utilizator varchar(100), @contPlata varchar(100), @numar varchar(20), @data datetime, @serie varchar(20), @xml xml, @tert varchar(20),
		@lm_agent varchar(20), @PCTLIV VARCHAR(20)

	set @tabel=CONVERT(xml, @parXML.value('(/*/@tabel)[1]','varchar(max)'))
	set @numar=@parXML.value('(/*/@numar)[1]','varchar(20)')
	set @serie=@parXML.value('(/*/@serie)[1]','varchar(20)')
	set @tert=@parXML.value('(/*/@tert)[1]','varchar(20)')
	set @pctliv=@parXML.value('(/*/@pctliv)[1]','varchar(20)')
	set @data=isnull(@parXML.value('(/*/@data)[1]','datetime'),convert(char(10),getdate(),101))

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
	select 
		@contPlata = rtrim(dbo.wfProprietateUtilizator('CONTPLIN', @utilizator)),
		@lm_agent = rtrim(dbo.wfProprietateUtilizator('LOCMUNCA', @utilizator))

	if isnull(@contPlata,'')=''
	begin
		raiserror('Cont casa nu este configurat pentru utilizatorul curent!',11,1)
	end

	/** Deserializam "tabelul" de facturi primit din XML */
	select
		D.c.value('(@factura)[1]','varchar(20)') factura,D.c.value('(@suma)[1]','float') suma
	into #listaFacturi
	FROM @tabel.nodes('/row') D(c)
	
	if isnull((select SUM(suma) from #listaFacturi),0)<=0
		raiserror('Suma de incasat trebuie sa fie pozitiva',16,1)
	
	if ISNULL(@numar,'')=''-- daca nu e completat numarul de chitanta in xml, il iau din plaja de IB
	begin
		declare @serieTMP varchar(50)
		
		set @xml= (select 'RE' tip,'PI' meniu,'IB' subtip, @utilizator utilizator for xml raw)
		exec wIauNrDocFiscale @parXML=@xml, @NrDoc=@numar output
	
		if @serie is null set @serie=isnull(@serieTMP,'')

	end

	if LEN(@numar)=0
	begin
		raiserror('Numar chitanta nu este completat sau plaja neconfigurata!',11,1)
	end

	/** Se formeaza XML-ul de trimis */
	set @xml=
		(
			select 
				'RE' tip, @contPlata cont, convert(varchar,@data,101) data,
					(
						select 
							'IB' subtip, l.factura factura, @numar numar, CONVERT(decimal(12,2),l.suma) suma, @tert tert,@lm_agent lm
						from #listaFacturi l 
						for xml raw,type
					)
			  for xml raw
		)

	exec wScriuPlin @sesiune=@sesiune, @parXML=@xml
--	select '' tabel for xml RAW('atribute'),root('Mesaje')

	delete from proprietati where Tip='U' and Cod=@utilizator and Cod_proprietate in ('SerieChitMobile', 'UltNumarChitMobile')

	if @serie is not null	
		insert proprietati(Tip, Cod, Cod_proprietate, Valoare, Valoare_tupla)
		values ('U', @utilizator, 'SerieChitMobile', @serie, '')
		
	if @numar is not null	
		insert proprietati(Tip, Cod, Cod_proprietate, Valoare, Valoare_tupla)
		values ('U', @utilizator, 'UltNumarChitMobile', @numar, '')

	/** Daca are form. chitanta incercam tiparirea */
	declare @formularIncasare varchar(20)
	select @formularIncasare = rtrim(dbo.wfProprietateUtilizator('FORMPLIN', @utilizator))
	select 'back(2)' as actiune for xml RAW, ROOT('Mesaje')
	if isnull(@formularIncasare,'')<>''
	begin
		-- tiparire chitanta
		set @xml=(select @contPlata cont, convert(varchar(10), GETDATE(),120) data, @numar numar, @tert tert, @pctliv pctliv for xml raw )
		exec wmTiparesteChitanta @sesiune=@sesiune, @parXML=@xml
	end	

end try
begin catch
	declare @eroare varchar(500)
	set @eroare=ERROR_MESSAGE()+'(wmProceseazaIncasare)'
	raiserror(@eroare,11,1)
end catch
