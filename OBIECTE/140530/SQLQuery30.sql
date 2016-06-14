select d.Suma_vama,d.Dif_vama,* from dvi d where d.Numar_receptie='1140616'
declare @parXMLC xml
	set @parXMLC=(select p.tip as tip, p.numar as numar, p.data as data, p.Numar_DVI as numarDVI, p.Data as dataDVI from pozdoc p where p.Tip='RM' and p.Numar='1140616'
	for xml raw)
	exec calculDVI @sesiune='', @parXML=@parXMLC
select d.Suma_vama,d.Dif_vama,* from dvi d where d.Numar_receptie='1140616'

declare @parXMLC xml
	set @parXMLC=(select p.tip as tip, p.numar as numar, p.data as data, p.Numar_DVI as numarDVI, p.Data as dataDVI from pozdoc p where p.Tip='RM' and p.Numar='1140601'
	for xml raw)
	exec calculDVI @sesiune='', @parXML=@parXMLC
select d.Suma_vama,d.Dif_vama,* from dvi d where d.Numar_receptie='1140601'