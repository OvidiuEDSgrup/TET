--***
CREATE procedure wScriuMfix @sesiune varchar(50), @parXML xml
as  
Declare @sub char(9), @alteinfomf int, @update bit, @nrinv varchar(20), @o_nrinv varchar(20), 
	@denmf varchar(80), @seriemf varchar(20), @codmfpublic char(20), @denmfpublic varchar(2000), 
	@denalternmf char(80), @prodmf char(80),@modelmf char(20),@nrinmatrmf char(20),
	@durfunct char(20), @staremf char(20), @datafabr datetime, @iDoc int, @detalii xml, @docDetalii xml

exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output
exec luare_date_par 'MF', 'ALTEINFO', @alteinfomf output, 0, ''


if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuMfixSP')
		exec wScriuMfixSP @sesiune, @parXML output

EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML

begin try
	select @update=isnull(ptupdate, 0), /*upper*/@nrinv=(ltrim(rtrim(nrinv))), 
		@o_nrinv=isnull(nrinv_vechi, nrinv), @denmf=ltrim(rtrim(denumire)),
		@denalternmf=ltrim(rtrim(isnull(denalternmf,''))), @seriemf=ltrim(rtrim(isnull(seriemf,''))), 
		@codmfpublic=ltrim(rtrim(isnull(codmfpublic,''))), @prodmf=ltrim(rtrim(isnull(prodmf,''))), 
		@modelmf=ltrim(rtrim(isnull(modelmf,''))), @nrinmatrmf=ltrim(rtrim(isnull(nrinmatrmf,''))), 
		@durfunct=ltrim(rtrim(isnull(durfunct,''))), @staremf=ltrim(rtrim(isnull(staremf,''))), 
		@datafabr=isnull(datafabr,'01/01/1901'), @detalii=detalii
	--into #xmlx
	from OPENXML(@iDoc, '/row')
	WITH
	(
		detalii xml 'detalii',
		ptupdate int '@update', 
		nrinv char(13) '@nrinv', 
		nrinv_vechi char(13) '@o_nrinv', 
		denumire char(80) '@denmf', 
		denalternmf char(80) '@denalternmf', 
		seriemf char(20) '@seriemf', 
		codmfpublic char(20) '@codmfpublic', 
		prodmf char(80) '@prodmf', 
		modelmf char(20) '@modelmf', 
		nrinmatrmf char(20) '@nrinmatrmf', 
		durfunct char(20) '@durfunct', 
		staremf char(20) '@staremf', 
		datafabr datetime '@datafabr'
	)
	
	exec sp_xml_removedocument @iDoc 
	
	--pt. pastrare 'ENTER' in detalii
	set @detalii = @parXML.query('(/row/detalii)[1]')
	
	if @update=0 --and isnull(@nrinv,'')<>@o_nrinv
	begin
		raiserror('Nu este permisa adaugarea de nr. de inventar decat prin doc. de tip intrare!',11,1)
		return
	end
	
	if @update=1 and isnull(@nrinv,'')<>@o_nrinv --and exists (select 1 from mismf where Numar_de_inventar=@o_nrinv)
	begin
		raiserror('Nu este permisa schimbarea nr. de inventar!',11,1)
		return
	end
	
	if (@update=0 or @update=1 and isnull(@nrinv,'')<>@o_nrinv) and exists (select 1 from mfix where Numar_de_inventar=@nrinv)
	begin
		raiserror('Acest nr. de inventar exista deja!',11,1)
		return
	end

	if isnull(@nrinv,'')='' 
	begin
		raiserror('Nr. de inventar necompletat!',11,1)
		return
	end
	
	if isnull(@denmf,'')='' --and not exists (select 1 from um where um.UM=@um)
	begin
		raiserror('Denumire necompletata!',11,1)
		return
	end
	
	SET @docDetalii = (
	SELECT @nrinv as nrinv,'mfix' as tabel, @detalii
	for xml raw
	)
	select @docDetalii
	exec wScriuDetalii @parXML=@docDetalii

	/*update t
	set tert=isnull(x.tert, t.tert), denumire=isnull(x.denumire, t.denumire), cod_fiscal=isnull(x.cod_fiscal, t.cod_fiscal), 
		localitate=isnull(x.localitate, t.localitate), 
		judet=isnull((case when isnull(x.tip_tert, 0)=0 then x.judet else x.tara end), t.judet), 
		adresa=isnull(x.adresa, t.adresa), 
		telefon_fax=isnull(x.telefon_fax, t.telefon_fax), banca=isnull(x.banca, t.banca), cont_in_banca=isnull(x.cont_in_banca, t.cont_in_banca), 
		tert_extern=isnull(x.decontari_valuta, t.tert_extern), grupa=isnull(x.grupa, t.grupa), 
		cont_ca_furnizor=isnull(x.cont_furnizor, t.cont_ca_furnizor), cont_ca_beneficiar=isnull(x.cont_beneficiar, t.cont_ca_beneficiar), 
		sold_ca_furnizor=isnull(693961 + datediff(d, '01/01/1901', x.data_tert), t.sold_ca_furnizor), 
		sold_ca_beneficiar=isnull(x.categ_pret, t.sold_ca_beneficiar), sold_maxim_ca_beneficiar=isnull(x.sold_maxim_beneficiar, t.sold_maxim_ca_beneficiar), disccount_acordat=isnull(x.discount, t.disccount_acordat)
	from terti t, #xmlx x
	where x.ptupdate=1 and t.subunitate=@Sub and t.tert=x.tert_vechi*/

	if @update=1  
	begin
		update mfix set Numar_de_inventar=@nrinv, Denumire=@denmf, Serie=@seriemf
			where Subunitate=@sub and Numar_de_inventar=@o_nrinv
		update mfix set Numar_de_inventar=@nrinv, Denumire=@denalternmf
			where Subunitate='DENS' and Numar_de_inventar=@o_nrinv
		delete from mfix where LEFT(subunitate,4)='DENS' and LEN(RTRIM(subunitate))>4 
			and Numar_de_inventar=@o_nrinv
		--mfix DENS2
		if @alteinfomf=1 INSERT into mfix (Subunitate,Numar_de_inventar,Denumire,Serie,
			Tip_amortizare,Cod_de_clasificare,Data_punerii_in_functiune)
			values 
			('DENS2',@nrinv,@prodmf,@modelmf,'',@nrinmatrmf,'01/01/1901')
		--mfix DENS3
		if @alteinfomf=1 INSERT into mfix (Subunitate,Numar_de_inventar,Denumire,Serie,
			Tip_amortizare,Cod_de_clasificare,Data_punerii_in_functiune)
			values 
			('DENS3',@nrinv,'',@durfunct,'',@staremf,@datafabr)
		--mfix DENS4
		if @codmfpublic<>'' INSERT into mfix (Subunitate,Numar_de_inventar,Denumire,Serie,
			Tip_amortizare,Cod_de_clasificare,Data_punerii_in_functiune)
			values 
			('DENS4',@nrinv,'',@codmfpublic,'','','01/01/1901')
	end
	else   
	begin
		declare @nrinv_par varchar(20)    
		/*if (isnull(@nrinv,'')='')  	
			exec wMaxCod 'cod','nomencl',@nrinv_par output
		else */
			set @nrinv_par=@nrinv --select * from MFix
	end
end try

begin catch
	declare @mesaj varchar(254)
	set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch 

--select @mesaj as mesajeroare for xml raw
