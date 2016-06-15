
create procedure wOPInlocuireDateMF @sesiune varchar(50), @parXML xml
as
begin try
	declare 
		@data datetime, @lm varchar(20), @comanda varchar(20), @gestiune varchar(20), @contam varchar(40), @contcham varchar(40), 
		@mesaj varchar(500), @nrinv varchar(50), @randuri int

	/**
		Procedura este aferenta operatiei de inlocuire date de pe macheta de "Mijloace fixe"
	**/

	set @data=@parXML.value('(/*/@dela)[1]','datetime')
	set @nrinv=@parXML.value('(/*/@nrinv)[1]','varchar(50)')
	set @lm=@parXML.value('(/*/@lm)[1]','varchar(20)')
	set @comanda=@parXML.value('(/*/@comanda)[1]','varchar(20)')
	set @gestiune=@parXML.value('(/*/@gest)[1]','varchar(20)')
	set @contam=@parXML.value('(/*/@contam)[1]','varchar(40)')
	set @contcham=@parXML.value('(/*/@contcham)[1]','varchar(40)')

	if @data is null
		raiserror('Data nu este corespunzatoare',16,1)

	if isnull(@nrinv ,'')=''
		raiserror('Nu s-a putut identifica mijlocul fix - numar de inventar incorect',16,1)

	update fisaMF
		set Loc_de_munca=isnull(@lm,Loc_de_munca), Comanda=isnull(@comanda,Comanda), Gestiune=isnull(@gestiune,Gestiune), 
			Cont_amortizare=isnull(@contam,Cont_amortizare), Cont_cheltuieli=isnull(@contcham,Cont_cheltuieli)
	where Numar_de_inventar=@nrinv and Data_lunii_operatiei>=@data

	set @randuri=@@rowcount

	if isnull(@randuri,0) > 0
		select 
			'Au fost actualizate '+CONVERT(varchar(10), @randuri) +' inregistrari' textMesaj, 'Actualizare cu succes!' as titluMesaj
		for XML raw, root('Mesaje')
end try

begin catch
	set @mesaj=ERROR_MESSAGE()+ ' (wOPInlocuireDateMF)'
	raiserror(@mesaj, 16,1)
end catch
