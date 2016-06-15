--***
/* Procedura apartine machetelor de configurare TB (categorii, indicatori )- asociaza unei categorii un indicator
verificand existenta lui in aceea categorie, corectitudinea codului, etc */

CREATE procedure wScriuIndicatorCategorie   @sesiune varchar(50), @parXML XML

as
declare @codCateg varchar(10), @codInd varchar(20), @o_codInd varchar(20), @doc XML,@err varchar(100), @rand decimal(5,2), @parinte varchar(20)

set	@codCateg = rtrim(isnull(@parXML.value('(/row/@codCat)[1]', 'varchar(10)'), ''))	
set	@codInd = rtrim(isnull(@parXML.value('(/row/row/@cod)[1]', 'varchar(20)'), ''))
set	@o_codInd = rtrim(isnull(@parXML.value('(/row/row/@o_cod)[1]', 'varchar(20)'), ''))
set @rand= isnull(@parXML.value('(/row/row/@rand)[1]', 'decimal(5,2)'), 0)
set @parinte= rtrim(isnull(@parXML.value('(/row/row/@parinte)[1]', 'varchar(20)'), ''))

if (@codInd='')
	begin
				set @err = 'Nu s-a selectat nici un indicator'
				RAISERROR(@err,16,1)
				return -1;
	end
-- de studiat daca e pe alta cetagorie!
if 1=0 and ((select COUNT(*) from compcategorii where Cod_Categ=@codCateg and Cod_Ind = @codInd)>0)
	begin
				set @err = (select 'Indicatorul: '+@codInd +'este asociat deja categoriei: '+@codCateg )
				RAISERROR(@err,16,1)
				return -1;
	end
if (@codCateg = '' )
	begin
		
				set @err = 'Nu s-a selectat nici o categorie careia sa i se ataseze indicatorul'
				RAISERROR(@err,16,1)
				return -1;
	end

if @codInd=@o_codInd -- modificarea unui rand
	update compcategorii set Parinte=@parinte, Rand=@rand where Cod_Categ=@codCateg and Cod_Ind=@codInd
else -- adaugare 
begin
	if @rand=0 set @rand= convert(decimal(5,2),isnull((select max(Rand)+1 from compcategorii where Cod_Categ=@codCateg),1))
	insert into compcategorii  values ( @codCateg,@codInd ,@rand,'' )
end
	
--set @doc ='<row codCat="'+rtrim(@codCateg)+'"/>'
--exec wIaIndicatori @sesiune=@sesiune, @parXML=@doc
