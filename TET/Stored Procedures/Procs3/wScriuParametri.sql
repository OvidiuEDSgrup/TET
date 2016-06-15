/** procedura de scriere pe functiilor pe locuri de munca **/
Create procedure wScriuParametri @sesiune varchar(30), @parXML XML
as
declare @tip varchar(100), @aplicatie varchar(100), @tab varchar(100), @subtab varchar(100), @componenta varchar(100), 
		@update bit, @tippar varchar(2), @parametru varchar(9), @o_tippar varchar(2), @o_parametru varchar(9), 
		@denpar varchar(30), @vallogica int, @valnumerica decimal(10,2), @valalfa varchar(200), @descriere varchar(8000), 
		@docXMLIaPar xml

if @parXML.exist('/Ierarhie')=1
begin
	Select	@tip = upper(@parXML.value('(/Ierarhie/row/@tip)[1]','varchar(100)')),
		@aplicatie = upper(@parXML.value('(/Ierarhie/row/@aplicatie)[1]','varchar(100)')),
		@tab = upper(@parXML.value('(/Ierarhie/row/@tab)[1]','varchar(100)')),
		@subtab = upper(@parXML.value('(/Ierarhie/row/@subtab)[1]','varchar(100)')),
		@componenta = upper(@parXML.value('(/Ierarhie/row/@componenta)[1]','varchar(100)')),
		@update = isnull(@parXML.value('(/Ierarhie/row/row/@update)[1]','bit'),isnull(@parXML.value('(/Ierarhie/row/@update)[1]','bit'),0)),
		@tippar = upper(isnull(@parXML.value('(/Ierarhie/row/row/@tippar)[1]','varchar(2)'),@parXML.value('(/Ierarhie/row/@tippar)[1]','varchar(2)'))),
		@parametru = upper(isnull(@parXML.value('(/Ierarhie/row/row/@parametru)[1]','varchar(9)'),isnull(@parXML.value('(/Ierarhie/row/@parametru)[1]','varchar(9)'),''))),
		@o_tippar = upper(@parXML.value('(/Ierarhie/row/row/@o_tippar)[1]','varchar(2)')),
		@o_parametru = upper(isnull(@parXML.value('(/Ierarhie/row/row/@o_parametru)[1]','varchar(9)'),'')),
		@denpar = isnull(@parXML.value('(/Ierarhie/row/row/@denpar)[1]','varchar(30)'),isnull(@parXML.value('(/Ierarhie/row/@denpar)[1]','varchar(30)'),'')),
		@vallogica = isnull(@parXML.value('(/Ierarhie/row/row/@vallogica)[1]','int'),isnull(@parXML.value('(/Ierarhie/row/@vallogica)[1]','int'),0)),
		@valnumerica = isnull(@parXML.value('(/Ierarhie/row/row/@valnumerica)[1]','decimal(12,3)'),isnull(@parXML.value('(/Ierarhie/row/@valnumerica)[1]','decimal(12,3)'),0)),
		@valalfa = isnull(@parXML.value('(/Ierarhie/row/row/@valalfa)[1]','varchar(200)'),isnull(@parXML.value('(/Ierarhie/row/@valalfa)[1]','varchar(200)'),'')),
		@descriere = isnull(@parXML.value('(/Ierarhie/row/row/@descriere)[1]','varchar(8000)'),isnull(@parXML.value('(/Ierarhie/row/@descriere)[1]','varchar(8000)'),''))
end
else 
begin
	Select	@tip = upper(@parXML.value('(/row/@tip)[1]','varchar(100)')),
		@aplicatie = upper(@parXML.value('(/row/@aplicatie)[1]','varchar(100)')),
		@tab = upper(@parXML.value('(/row/@tab)[1]','varchar(100)')),
		@componenta = upper(@parXML.value('(/row/@componenta)[1]','varchar(100)')),
		@subtab = upper(@parXML.value('(/row/row/@subtab)[1]','varchar(100)')),
		@update = isnull(@parXML.value('(/row/row/@update)[1]','bit'),0),
		@tippar = upper(@parXML.value('(/row/row/@tippar)[1]','varchar(2)')),
		@parametru = upper(isnull(@parXML.value('(/row/row/@parametru)[1]','varchar(9)'),'')),
		@o_tippar = upper(@parXML.value('(/row/row/@o_tippar)[1]','varchar(2)')),
		@o_parametru = upper(isnull(@parXML.value('(/row/row/@o_parametru)[1]','varchar(9)'),'')),
		@denpar = isnull(@parXML.value('(/row/row/@denpar)[1]','varchar(30)'),''),
		@vallogica = isnull(@parXML.value('(/row/row/@vallogica)[1]','int'),0),
		@valnumerica = isnull(@parXML.value('(/row/row/@valnumerica)[1]','decimal(12,3)'),0),
		@valalfa = isnull(@parXML.value('(/row/row/@valalfa)[1]','varchar(200)'),''),
		@descriere = isnull(@parXML.value('(/row/row/@descriere)[1]','varchar(8000)'),'')
end
--select @tip, @aplicatie, @tab, @subtab, @componenta
begin try
	declare @tip_parametru char(2), @par varchar(9)
	set @tip_parametru=(case when @o_tippar<>'' then @o_tippar else @tippar end)
	set @par=(case when @o_parametru<>'' then @o_parametru else @parametru end)

	exec setare_par @tip_parametru, @par, @denpar, @vallogica, @valnumerica, @valalfa

	set @docXMLIaPar='<row tip="'+rtrim(@tip)+'" aplicatie="'+rtrim(@aplicatie)+'" tab="'+rtrim(@tab)+'" componenta="'+rtrim(@subtab)+'"/>'
	exec wIaParametri @sesiune=@sesiune, @parXML=@docXMLIaPar
end try

begin catch
	declare @mesaj varchar(254)
	set @mesaj = '(wScriuParametri) '+ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch
