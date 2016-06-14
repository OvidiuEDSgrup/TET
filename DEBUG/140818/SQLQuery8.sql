select p.Procent_vama,* from pozdoc p where p.Subunitate='1' and p.tert='ATU19208701'
and p.Data between '2014-07-01' and '2014-07-31'

exec Declaratia390 @datajos='2014-07-01', @datasus='2014-07-31'
	,@d_rec=0
	,@nume_declar='BRUMA', @prenume_declar='MARIA', @functie_declar='DIR ECONOMIC'
	,@cui=null, @den=null, @adresa=null, @telefon=null
	,@fax=null, @mail=null
	,@caleFisier='\\10.0.0.10\declaratii\390_0714_J6610440.xml'
	,@dinRia=0
	,@nrPagini='  1'
	,@RP ='1'
	,@FF ='1'
	,@listaFF ='404.0                                                                                                                                                                                                   '
	,@FB ='1'
	,@listaFB ='411.3                                                                                                                                                                                                   '
	,@AS ='1'
	
--ATU19208701