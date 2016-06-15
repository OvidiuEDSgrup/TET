--***
create procedure rapMFListadeInventariere @data datetime, @gestiune varchar(20)=null,
	@cont varchar(20)=null, @cod varchar(20)=null,
	@tipPatrimoniu smallint=3,	--> filtru pe tip patrimoniu: 3=Toate, 2=Privat, 1=Public
	@tipImobilizare int='1',		--> tip imobilizare:	1=M. fixe, 2=Obiecte inventar, 3=MF dupa casare
	@locm varchar(50) = null,	--> filtru pe loc de munca
	@categorie varchar(50) = null, --> filtru pe categorie
	@grupare int = 7	--> Valori grupare: 4=categorie, 7=cont mf
as
begin

	declare @tipimob nvarchar(1),@lista nvarchar(1),@cLocMunca varchar(30),
			@pComanda varchar(30),@serie varchar(30),@categoria varchar(30),
			@tippatrim nvarchar(1),@nrInventar varchar(20),@mfPublice bit,
			@contAmortizare varchar(30),@codClasificare varchar(30),@indbug varchar(30), 
			@tipActiv smallint
			
	select	@tipimob=@tipImobilizare,@lista=N'1',@cLocMunca=@locm,@pComanda=NULL,@serie=NULL,
			@categoria=@categorie,@tippatrim=@tipPatrimoniu,@grupare=@grupare,@nrInventar=@cod,@mfPublice=0,
			@contAmortizare=NULL,@codClasificare=NULL,@indbug=NULL,@tipActiv=N'0'
			
	exec rapMFregistru @tipimob=@tipimob, @lista=@lista, @data=@data, @cLocMunca=@cLocMunca, 
		@pComanda=@pComanda, @serie=@serie, @cont=@cont, @categoria=@categoria, @tippatrim=@tippatrim, 
		@grupare=@grupare, @gestiune=@gestiune, @contAmortizare=@contAmortizare, 
		@codClasificare=@codClasificare, @indbug=@indbug, @nrInventar=@nrInventar, 
		@mfPublice=@mfPublice, @tipActiv=@tipActiv, @tipraport='Li'
		
end
