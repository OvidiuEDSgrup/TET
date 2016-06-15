--***
CREATE procedure yso_wIaProprietatiNomencl   @sesiune varchar(30), @parXML XML as

--declare @sesiune varchar(30), @parXML XML 
--set @parXML=convert(xml,N'<row tert="RO18576910" dentert="ELRAD SRL" codfiscal="10867728" localitate="8288" denlocalitate="BAIA MARE" judet="MM" denjudet="MARAMURES" tara="" dentara="" adresa="CIPRIAN PORUMBESCU55" strada="CIPRIAN PORUMBESCU55" numar="" bloc="" scara="" apartament="" codpostal="" telefonfax="" banca="" denbanca="" continbanca="" decontarivaluta="0" grupa="109" dengrupa="" contfurn="401.2" dencontfurn="Furnizori marfa intern" contben="411.1" dencontben="Clienti interni" datatert="01/01/1901" categpret="0" dencategpret="" soldmaxben="0.00" discount="0.00" termenlivrare="0" termenscadenta="0" reprezentant="" functiereprezentant="" lm="" denlm="" responsabil="03001" denresponsabil="" info1="" info2="raduvasile96@yahoo.com" info3="" nrordreg="J24/442/1998" tiptert="0" neplatitortva="0" nomspec="0" soldfurn="0.00" soldben="0.00" culoare="#000000" subcontractant="" tip="PT"/>')
--set @sesiune='943309A1879A5'

declare @codprop varchar(20),@cautare varchar(100), @cod varchar(13), @fltDescriere varchar(80)

select @cod = isnull(@parXML.value('(/row/@cod)[1]','varchar(13)'),'')
	,@cautare=isnull(@parXML.value('(/row/@_cautare)[1]','varchar(200)'),'')
	,@fltDescriere = isnull(@parXML.value('(/row/@descriere)[1]', 'varchar(80)'), '')
	,@codprop=isnull(@parXML.value('(/row/@codprop)[1]','varchar(20)'),'')

set @cautare=REPLACE(@cautare,' ','%')

select distinct 
       RTRIM(cod) as cod,
       rtrim(p.Cod_proprietate) as codprop,
	   RTRIM(cp.descriere) as descriere,
	   RTRIM(p.Valoare) as valoare,
	   RTRIM(ISNULL(v.Descriere,'')) as denvaloare
	   from proprietati p
		inner join catproprietati cp on cp.Cod_proprietate=p.Cod_proprietate 
		left join valproprietati v on v.Cod_proprietate=p.Cod_proprietate and v.Valoare=p.Valoare
	   where p.Tip='NOMENCL' and (@cod='' or p.cod=@cod) and p.Cod<>''
			and (@codprop='' or p.Cod_proprietate=@codprop)
			and (@cautare='' or (p.Cod_proprietate like '%'+@cautare+'%'  or cp.Descriere like '%'+@cautare+'%')) 
for xml raw

--select * from catproprietati
 --select * from proprietati
-- valproprietati