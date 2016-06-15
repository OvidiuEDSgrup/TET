
CREATE PROCEDURE wOPDeschidereAnalitic @sesiune varchar(50), @parXML xml
as
begin try
	declare 
		@cont varchar(20), @cont_analitic varchar(20), @denumire_analitic varchar(200), @docInloc xml

	select
		@cont=@parXML.value('(/*/@cont)[1]','varchar(20)'),
		@cont_analitic=UPPER(@parXML.value('(/*/@cont_analitic)[1]','varchar(20)')),
		@denumire_analitic=UPPER(@parXML.value('(/*/@denumire_analitic)[1]','varchar(200)'))

	
	IF @cont_analitic not like @cont+'%'
		raiserror('Contul nou nu reprezinta un analitic al contului vechi!',16,1)	

	begin tran
		alter table Conturi disable trigger all
			update Conturi set Are_analitice=1 where cont=@cont
		alter table Conturi enable trigger all

		insert into Conturi(Subunitate, Cont, Denumire_cont, Tip_cont, Cont_parinte, Are_analitice, Apare_in_balanta_sintetica, Sold_debit, Sold_credit, Nivel, Articol_de_calculatie, Logic, detalii)
		select Subunitate, @cont_analitic, @denumire_analitic, Tip_cont, @cont, 0, Apare_in_balanta_sintetica, Sold_debit, Sold_credit, Nivel+1, Articol_de_calculatie, Logic, NULL
		from Conturi where cont=@cont

		set @docInloc=(select @cont cont_vechi, @cont_analitic cont_nou for xml raw)
		exec wOPInlocuireCont @sesiune=@sesiune,@parXML=@docInloc
	
	commit tran

end try
begin catch
	IF @@TRANCOUNT>0
		ROLLBACK TRAN
	
	declare @mesaj varchar(2000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch 
