--***
create procedure [wScriuDecaux] @sesiune varchar(50), @parXML xml 
as

declare @sub char(9), @numar_document varchar(8), @data datetime, 
	@l_m_furnizor varchar(9), @comanda_furnizor varchar(13),  
	@loc_de_munca_beneficiar varchar(9), @comanda_beneficiar varchar(13),
	@articol_de_calculatie_benef varchar(9), 
	@cantitate float, @valoare float, @automat bit,
	@mesaj varchar(255), @eroare xml,@docXMLIaPozDecaux xml

begin try
	--BEGIN TRAN
		set @eroare = dbo.wfValidareDecaux(@parXML)
		--if isnull(@eroare.value('(error/@coderoare)[1]', 'int'), 0)>0
		set @mesaj=isnull(@eroare.value('(/error/@msgeroare)[1]', 'varchar(200)'), '<Eroare>')
		if @mesaj <> '' 
			raiserror(@mesaj, 11, 1)
		set @automat=0
		declare @iDoc int
		EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
		--
		declare crspozncon cursor for
		select 
		
		numar_document,
		data, 
		l_m_furnizor, 
		comanda_furnizor,  
		isnull(loc_de_munca_beneficiar,'') as loc_de_munca_beneficiar, 
		isnull(comanda_beneficiar,'') as comanda_beneficiar,
		isnull(articol_de_calculatie_benef,'') as articol_de_calculatie_benef, 
		cantitate, 
		isnull(valoare,0) as valoare, 
		automat
		
		from OPENXML(@iDoc, '/row')
		WITH 
		(
			numar_document varchar(8) '/row/row/@numar_document',
			data datetime '@data',
			l_m_furnizor varchar(9) '@l_m_furnizor',
			comanda_furnizor varchar(13) '@comanda_furnizor', 
			loc_de_munca_beneficiar varchar(9) '/row/row/@loc_de_munca_beneficiar',
			comanda_beneficiar varchar(13) '/row/row/@comanda_beneficiar', 			
			articol_de_calculatie_benef varchar(9) '/row/row/@articol_de_calculatie_benef',
			cantitate float '/row/row/@cantitate',
			valoare float '/row/row/@valoare',
			automat bit '/row/row/@automat'
		)
		--
		open crspozncon
		fetch next from crspozncon into 
		@numar_document, @data, 
		@l_m_furnizor, @comanda_furnizor, 
		@loc_de_munca_beneficiar, @comanda_beneficiar, 
		@articol_de_calculatie_benef, @cantitate, @valoare, @automat
		while @@fetch_status = 0
		begin
			if isnull(@numar_document,'')=''
				begin
					declare @nr int
					set @nr=--isnull((select COUNT(1) from decaux where year(data)=year(@data) and month(data)=month(@data) group by subunitate),0)
					isnull((select MAX(convert(int,(case when isnumeric(numar_document)=1 then numar_document else 0 end)))
						 from decaux where year(data)=year(@data) and month(data)=month(@data) group by subunitate),0)
					set @nr=@nr+1
					set @numar_document=cast(@nr as varchar(8))
				end
			--
			set @Articol_de_calculatie_benef=isnull((select val_alfanumerica from par where Tip_parametru='PC' and Parametru='ARTCALT' and Val_logica=1),'3')
			--
			if not exists 
			(
			select 1 from decaux where subunitate  = '1' and numar_document=@numar_document and data=@data 
			and l_m_furnizor=@l_m_furnizor and comanda_furnizor=@comanda_furnizor 
			)
					--Adaugare pozitie noua
					insert into decaux (Subunitate,Numar_document,Data,L_m_furnizor,Comanda_furnizor,
					                    Loc_de_munca_beneficiar,Comanda_beneficiar,Articol_de_calculatie_benef,
					                    Cantitate,Valoare,Automat) 
					values ('1',@Numar_document,@Data,@L_m_furnizor,@Comanda_furnizor,
					                    '','','',
					                    @cantitate,0,0) 
						
			--Modificare pozitie existenta
			update decaux set 
			loc_de_munca_beneficiar=@loc_de_munca_beneficiar, 
			comanda_beneficiar=@comanda_beneficiar, 
			Articol_de_calculatie_benef=@Articol_de_calculatie_benef, 
			Cantitate=@Cantitate, 
			automat=0
			where subunitate='1' and Numar_document=@Numar_document and data=@data 
			and l_m_furnizor=@l_m_furnizor and comanda_furnizor=@comanda_furnizor 
						
			fetch next from crspozncon into 
			@numar_document, @data, 
			@l_m_furnizor, @comanda_furnizor, 
			@loc_de_munca_beneficiar, @comanda_beneficiar, 
			@articol_de_calculatie_benef, @cantitate, @valoare, @automat
		end
		--
		update decaux set automat=0 where subunitate='1' and data=@data and l_m_furnizor=@l_m_furnizor and comanda_furnizor=@comanda_furnizor -- se forteaza ca manuale toate pozitiile.
		--
		exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output
		set @docXMLIaPozDecaux = '<row tip="DX" subtip="DX" subunitate="' + rtrim('1') + ' " numar_document="' + rtrim(@numar_document) + '" data="' + convert(char(10), @data, 101) 
		+ ' " l_m_furnizor="' + rtrim(@l_m_furnizor) + ' " comanda_furnizor="' + rtrim(@comanda_furnizor) + '"/>'
		exec wIaPozDecaux @sesiune=@sesiune, @parXML=@docXMLIaPozDecaux
		--
	--COMMIT TRAN
end try
--
begin catch
	--ROLLBACK TRAN
	--if isnull(@eroare.value('(/error/@coderoare)[1]', 'int'), 0) = 0
	set @mesaj = ERROR_MESSAGE() 
	--set @mesaj='<error coderoare="1" msgeroare="' + ERROR_MESSAGE() + '"/>'
	raiserror(@mesaj, 11, 1)
end catch
--
IF OBJECT_ID('crspozdoc') IS NOT NULL
	begin
	close crspozdoc 
	deallocate crspozdoc 
	end
--
begin try 
	exec sp_xml_removedocument @iDoc 
end try 
--
begin catch end catch


