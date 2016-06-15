CREATE XML SCHEMA COLLECTION [dbo].[ASchemaRevisal]
    AS N'<xsd:schema xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:t="http://schemas.microsoft.com/2003/10/Serialization/" targetNamespace="http://schemas.microsoft.com/2003/10/Serialization/">
  <xsd:attribute name="FactoryType" type="xsd:QName" />
  <xsd:attribute name="Id" type="xsd:ID" />
  <xsd:attribute name="Ref" type="xsd:IDREF" />
  <xsd:element name="QName" type="xsd:QName" nillable="true" />
  <xsd:element name="anyType" type="xsd:anyType" nillable="true" />
  <xsd:element name="anyURI" type="xsd:anyURI" nillable="true" />
  <xsd:element name="base64Binary" type="xsd:base64Binary" nillable="true" />
  <xsd:element name="boolean" type="xsd:boolean" nillable="true" />
  <xsd:element name="byte" type="xsd:byte" nillable="true" />
  <xsd:element name="char" type="t:char" nillable="true" />
  <xsd:element name="dateTime" type="xsd:dateTime" nillable="true" />
  <xsd:element name="decimal" type="xsd:decimal" nillable="true" />
  <xsd:element name="double" type="xsd:double" nillable="true" />
  <xsd:element name="duration" type="t:duration" nillable="true" />
  <xsd:element name="float" type="xsd:float" nillable="true" />
  <xsd:element name="guid" type="t:guid" nillable="true" />
  <xsd:element name="int" type="xsd:int" nillable="true" />
  <xsd:element name="long" type="xsd:long" nillable="true" />
  <xsd:element name="short" type="xsd:short" nillable="true" />
  <xsd:element name="string" type="xsd:string" nillable="true" />
  <xsd:element name="unsignedByte" type="xsd:unsignedByte" nillable="true" />
  <xsd:element name="unsignedInt" type="xsd:unsignedInt" nillable="true" />
  <xsd:element name="unsignedLong" type="xsd:unsignedLong" nillable="true" />
  <xsd:element name="unsignedShort" type="xsd:unsignedShort" nillable="true" />
  <xsd:simpleType name="char">
    <xsd:restriction base="xsd:int" />
  </xsd:simpleType>
  <xsd:simpleType name="duration">
    <xsd:restriction base="xsd:duration">
      <xsd:pattern value="\-?P(\d*D)?(T(\d*H)?(\d*M)?(\d*(\.\d*)?S)?)?" />
    </xsd:restriction>
  </xsd:simpleType>
  <xsd:simpleType name="guid">
    <xsd:restriction base="xsd:string">
      <xsd:pattern value="[\da-fA-F]{8}-[\da-fA-F]{4}-[\da-fA-F]{4}-[\da-fA-F]{4}-[\da-fA-F]{12}" />
    </xsd:restriction>
  </xsd:simpleType>
</xsd:schema>
<xsd:schema xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:t="http://schemas.datacontract.org/2004/07/uNhAddIns.Entities" targetNamespace="http://schemas.datacontract.org/2004/07/uNhAddIns.Entities">
  <xsd:element name="AbstractEntityOfguid" type="t:AbstractEntityOfguid" nillable="true" />
  <xsd:element name="Entity" type="t:Entity" nillable="true" />
  <xsd:complexType name="AbstractEntityOfguid">
    <xsd:complexContent>
      <xsd:restriction base="xsd:anyType">
        <xsd:sequence />
      </xsd:restriction>
    </xsd:complexContent>
  </xsd:complexType>
  <xsd:complexType name="Entity">
    <xsd:complexContent>
      <xsd:extension base="t:AbstractEntityOfguid">
        <xsd:sequence />
      </xsd:extension>
    </xsd:complexContent>
  </xsd:complexType>
</xsd:schema>
<xsd:schema xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:ns1="http://schemas.microsoft.com/2003/10/Serialization/" xmlns:ns2="http://schemas.datacontract.org/2004/07/uNhAddIns.Entities" xmlns:t="http://schemas.datacontract.org/2004/07/Revisal.Entities" targetNamespace="http://schemas.datacontract.org/2004/07/Revisal.Entities" elementFormDefault="qualified">
  <xsd:import namespace="http://schemas.microsoft.com/2003/10/Serialization/" />
  <xsd:import namespace="http://schemas.datacontract.org/2004/07/uNhAddIns.Entities" />
  <xsd:element name="ActIdentitatePF" type="t:ActIdentitatePF" nillable="true" />
  <xsd:element name="Angajator" type="t:Angajator" nillable="true" />
  <xsd:element name="ArrayOfContract" type="t:ArrayOfContract" nillable="true" />
  <xsd:element name="ArrayOfSalariat" type="t:ArrayOfSalariat" nillable="true" />
  <xsd:element name="ArrayOfSpor" type="t:ArrayOfSpor" nillable="true" />
  <xsd:element name="AuditableEntity" type="t:AuditableEntity" nillable="true" />
  <xsd:element name="Contact" type="t:Contact" nillable="true" />
  <xsd:element name="Contract" type="t:Contract" nillable="true" />
  <xsd:element name="ContractStare" type="t:ContractStare" nillable="true" />
  <xsd:element name="ContractStareActiv" type="t:ContractStareActiv" nillable="true" />
  <xsd:element name="ContractStareDetasare" type="t:ContractStareDetasare" nillable="true" />
  <xsd:element name="ContractStareIncetare" type="t:ContractStareIncetare" nillable="true" />
  <xsd:element name="ContractStareReactivare" type="t:ContractStareReactivare" nillable="true" />
  <xsd:element name="ContractStareSuspendare" type="t:ContractStareSuspendare" nillable="true" />
  <xsd:element name="Cor" type="t:Cor" nillable="true" />
  <xsd:element name="DetaliiAngajator" type="t:DetaliiAngajator" nillable="true" />
  <xsd:element name="DetaliiAngajatorPersoanaFizica" type="t:DetaliiAngajatorPersoanaFizica" nillable="true" />
  <xsd:element name="DetaliiAngajatorPersoanaJuridica" type="t:DetaliiAngajatorPersoanaJuridica" nillable="true" />
  <xsd:element name="DetaliiSalariatStrain" type="t:DetaliiSalariatStrain" nillable="true" />
  <xsd:element name="DomeniuActivitate" type="t:DomeniuActivitate" nillable="true" />
  <xsd:element name="ExceptieDataSfarsit" type="t:ExceptieDataSfarsit" nillable="true" />
  <xsd:element name="FormaJuridicaPF" type="t:FormaJuridicaPF" nillable="true" />
  <xsd:element name="FormaJuridicaPJ" type="t:FormaJuridicaPJ" nillable="true" />
  <xsd:element name="FormaOrganizarePF" type="t:FormaOrganizarePF" nillable="true" />
  <xsd:element name="FormaOrganizarePJ" type="t:FormaOrganizarePJ" nillable="true" />
  <xsd:element name="FormaProprietate" type="t:FormaProprietate" nillable="true" />
  <xsd:element name="Header" type="t:Header" nillable="true" />
  <xsd:element name="Localitate" type="t:Localitate" nillable="true" />
  <xsd:element name="Nationalitate" type="t:Nationalitate" nillable="true" />
  <xsd:element name="NivelInfiintare" type="t:NivelInfiintare" nillable="true" />
  <xsd:element name="NormaTimpMunca" type="t:NormaTimpMunca" nillable="true" />
  <xsd:element name="RepartizareIntervalTimp" type="t:RepartizareIntervalTimp" nillable="true" />
  <xsd:element name="RepartizareTimpMunca" type="t:RepartizareTimpMunca" nillable="true" />
  <xsd:element name="Salariat" type="t:Salariat" nillable="true" />
  <xsd:element name="Spor" type="t:Spor" nillable="true" />
  <xsd:element name="TemeiIncetare" type="t:TemeiIncetare" nillable="true" />
  <xsd:element name="TemeiReactivare" type="t:TemeiReactivare" nillable="true" />
  <xsd:element name="TemeiSuspendare" type="t:TemeiSuspendare" nillable="true" />
  <xsd:element name="TimpMunca" type="t:TimpMunca" nillable="true" />
  <xsd:element name="TipActIdentitate" type="t:TipActIdentitate" nillable="true" />
  <xsd:element name="TipAutorizatie" type="t:TipAutorizatie" nillable="true" />
  <xsd:element name="TipContract" type="t:TipContract" nillable="true" />
  <xsd:element name="TipDurata" type="t:TipDurata" nillable="true" />
  <xsd:element name="TipNorma" type="t:TipNorma" nillable="true" />
  <xsd:element name="TipSpor" type="t:TipSpor" nillable="true" />
  <xsd:element name="TipSporAngajator" type="t:TipSporAngajator" nillable="true" />
  <xsd:element name="TipSporPredefinit" type="t:TipSporPredefinit" nillable="true" />
  <xsd:element name="XmlReport" type="t:XmlReport" nillable="true" />
  <xsd:complexType name="Angajator">
    <xsd:complexContent>
      <xsd:extension base="t:AuditableEntity">
        <xsd:sequence>
          <xsd:element name="Adresa">
            <xsd:simpleType>
              <xsd:restriction base="xsd:string">
                <xsd:maxLength value="256" />
              </xsd:restriction>
            </xsd:simpleType>
          </xsd:element>
          <xsd:element name="Contact" type="t:Contact" minOccurs="0" nillable="true" />
          <xsd:element name="Detalii" type="t:DetaliiAngajator" />
          <xsd:element name="Localitate" type="t:Localitate" />
        </xsd:sequence>
      </xsd:extension>
    </xsd:complexContent>
  </xsd:complexType>
  <xsd:complexType name="ArrayOfContract">
    <xsd:complexContent>
      <xsd:restriction base="xsd:anyType">
        <xsd:sequence>
          <xsd:element name="Contract" type="t:Contract" maxOccurs="unbounded" />
        </xsd:sequence>
      </xsd:restriction>
    </xsd:complexContent>
  </xsd:complexType>
  <xsd:complexType name="ArrayOfSalariat">
    <xsd:complexContent>
      <xsd:restriction base="xsd:anyType">
        <xsd:sequence>
          <xsd:element name="Salariat" type="t:Salariat" maxOccurs="unbounded" />
        </xsd:sequence>
      </xsd:restriction>
    </xsd:complexContent>
  </xsd:complexType>
  <xsd:complexType name="ArrayOfSpor">
    <xsd:complexContent>
      <xsd:restriction base="xsd:anyType">
        <xsd:sequence>
          <xsd:element name="Spor" type="t:Spor" maxOccurs="unbounded" />
        </xsd:sequence>
      </xsd:restriction>
    </xsd:complexContent>
  </xsd:complexType>
  <xsd:complexType name="AuditableEntity">
    <xsd:complexContent>
      <xsd:extension base="ns2:Entity">
        <xsd:sequence />
      </xsd:extension>
    </xsd:complexContent>
  </xsd:complexType>
  <xsd:complexType name="Contact">
    <xsd:complexContent>
      <xsd:restriction base="xsd:anyType">
        <xsd:sequence>
          <xsd:element name="Email" minOccurs="0" nillable="true">
            <xsd:simpleType>
              <xsd:restriction base="xsd:string">
                <xsd:maxLength value="256" />
              </xsd:restriction>
            </xsd:simpleType>
          </xsd:element>
          <xsd:element name="Fax" minOccurs="0" nillable="true">
            <xsd:simpleType>
              <xsd:restriction base="xsd:string">
                <xsd:maxLength value="256" />
              </xsd:restriction>
            </xsd:simpleType>
          </xsd:element>
          <xsd:element name="ReprezentantLegal" minOccurs="0" nillable="true">
            <xsd:simpleType>
              <xsd:restriction base="xsd:string">
                <xsd:maxLength value="256" />
              </xsd:restriction>
            </xsd:simpleType>
          </xsd:element>
          <xsd:element name="Telefon" minOccurs="0" nillable="true">
            <xsd:simpleType>
              <xsd:restriction base="xsd:string">
                <xsd:maxLength value="256" />
              </xsd:restriction>
            </xsd:simpleType>
          </xsd:element>
        </xsd:sequence>
      </xsd:restriction>
    </xsd:complexContent>
  </xsd:complexType>
  <xsd:complexType name="Contract">
    <xsd:complexContent>
      <xsd:extension base="t:AuditableEntity">
        <xsd:sequence>
          <xsd:element name="Cor" type="t:Cor" />
          <xsd:element name="DataConsemnare" type="xsd:dateTime" />
          <xsd:element name="DataContract" type="xsd:dateTime" />
          <xsd:element name="DataInceputContract" type="xsd:dateTime" />
          <xsd:element name="DataSfarsitContract" type="xsd:dateTime" minOccurs="0" nillable="true" />
          <xsd:element name="DateContractVechi" minOccurs="0" nillable="true">
            <xsd:simpleType>
              <xsd:restriction base="xsd:string">
                <xsd:maxLength value="256" />
              </xsd:restriction>
            </xsd:simpleType>
          </xsd:element>
          <xsd:element name="Detalii" minOccurs="0" nillable="true">
            <xsd:simpleType>
              <xsd:restriction base="xsd:string">
                <xsd:maxLength value="256" />
              </xsd:restriction>
            </xsd:simpleType>
          </xsd:element>
          <xsd:element name="ExceptieDataSfarsit" type="t:ExceptieDataSfarsit" minOccurs="0" nillable="true" />
          <xsd:element name="NumarContract">
            <xsd:simpleType>
              <xsd:restriction base="xsd:string">
                <xsd:maxLength value="256" />
              </xsd:restriction>
            </xsd:simpleType>
          </xsd:element>
          <xsd:element name="NumereContractVechi" minOccurs="0" nillable="true">
            <xsd:simpleType>
              <xsd:restriction base="xsd:string">
                <xsd:maxLength value="256" />
              </xsd:restriction>
            </xsd:simpleType>
          </xsd:element>
          <xsd:element name="Salariu" type="xsd:int" />
          <xsd:element name="SporuriSalariu" type="t:ArrayOfSpor" minOccurs="0" nillable="true" />
          <xsd:element name="StareCurenta" type="t:ContractStare" />
          <xsd:element name="TimpMunca" type="t:TimpMunca" />
          <xsd:element name="TipContract" type="t:TipContract" />
          <xsd:element name="TipDurata" type="t:TipDurata" />
          <xsd:element name="TipNorma" type="t:TipNorma" />
        </xsd:sequence>
      </xsd:extension>
    </xsd:complexContent>
  </xsd:complexType>
  <xsd:complexType name="ContractStare">
    <xsd:complexContent>
      <xsd:extension base="t:AuditableEntity">
        <xsd:sequence>
          <xsd:element name="DataIncetareDetasare" type="xsd:dateTime" minOccurs="0" nillable="true" />
          <xsd:element name="DataIncetareSuspendare" type="xsd:dateTime" minOccurs="0" nillable="true" />
          <xsd:element name="StarePrecedenta" type="t:ContractStare" minOccurs="0" nillable="true" />
        </xsd:sequence>
      </xsd:extension>
    </xsd:complexContent>
  </xsd:complexType>
  <xsd:complexType name="ContractStareActiv">
    <xsd:complexContent>
      <xsd:extension base="t:ContractStare">
        <xsd:sequence />
      </xsd:extension>
    </xsd:complexContent>
  </xsd:complexType>
  <xsd:complexType name="ContractStareDetasare">
    <xsd:complexContent>
      <xsd:extension base="t:ContractStare">
        <xsd:sequence>
          <xsd:element name="AngajatorCui">
            <xsd:simpleType>
              <xsd:restriction base="xsd:string">
                <xsd:maxLength value="256" />
              </xsd:restriction>
            </xsd:simpleType>
          </xsd:element>
          <xsd:element name="AngajatorNume">
            <xsd:simpleType>
              <xsd:restriction base="xsd:string">
                <xsd:maxLength value="256" />
              </xsd:restriction>
            </xsd:simpleType>
          </xsd:element>
          <xsd:element name="DataInceput" type="xsd:dateTime" />
          <xsd:element name="DataIncetare" type="xsd:dateTime" minOccurs="0" nillable="true" />
          <xsd:element name="DataSfarsit" type="xsd:dateTime" />
          <xsd:element name="Nationalitate" type="t:Nationalitate" />
        </xsd:sequence>
      </xsd:extension>
    </xsd:complexContent>
  </xsd:complexType>
  <xsd:complexType name="ContractStareIncetare">
    <xsd:complexContent>
      <xsd:extension base="t:ContractStare">
        <xsd:sequence>
          <xsd:element name="DataIncetare" type="xsd:dateTime" />
          <xsd:element name="TemeiLegal" type="t:TemeiIncetare" />
        </xsd:sequence>
      </xsd:extension>
    </xsd:complexContent>
  </xsd:complexType>
  <xsd:complexType name="ContractStareReactivare">
    <xsd:complexContent>
      <xsd:extension base="t:ContractStareActiv">
        <xsd:sequence>
          <xsd:element name="DataReactivare" type="xsd:dateTime" />
          <xsd:element name="TemeiLegal" type="t:TemeiReactivare" />
        </xsd:sequence>
      </xsd:extension>
    </xsd:complexContent>
  </xsd:complexType>
  <xsd:complexType name="ContractStareSuspendare">
    <xsd:complexContent>
      <xsd:extension base="t:ContractStare">
        <xsd:sequence>
          <xsd:element name="DataInceput" type="xsd:dateTime" />
          <xsd:element name="DataIncetare" type="xsd:dateTime" minOccurs="0" nillable="true" />
          <xsd:element name="DataSfarsit" type="xsd:dateTime" minOccurs="0" nillable="true" />
          <xsd:element name="TemeiLegal" type="t:TemeiSuspendare" />
        </xsd:sequence>
      </xsd:extension>
    </xsd:complexContent>
  </xsd:complexType>
  <xsd:complexType name="Cor">
    <xsd:complexContent>
      <xsd:extension base="ns2:Entity">
        <xsd:sequence>
          <xsd:element name="Cod" type="xsd:int" />
          <xsd:element name="Versiune" type="xsd:int" />
        </xsd:sequence>
      </xsd:extension>
    </xsd:complexContent>
  </xsd:complexType>
  <xsd:complexType name="DetaliiAngajator">
    <xsd:complexContent>
      <xsd:extension base="t:AuditableEntity">
        <xsd:sequence>
          <xsd:element name="DomeniuActivitate" type="t:DomeniuActivitate" minOccurs="0" nillable="true" />
          <xsd:element name="Nume">
            <xsd:simpleType>
              <xsd:restriction base="xsd:string">
                <xsd:maxLength value="256" />
              </xsd:restriction>
            </xsd:simpleType>
          </xsd:element>
        </xsd:sequence>
      </xsd:extension>
    </xsd:complexContent>
  </xsd:complexType>
  <xsd:complexType name="DetaliiAngajatorPersoanaFizica">
    <xsd:complexContent>
      <xsd:extension base="t:DetaliiAngajator">
        <xsd:sequence>
          <xsd:element name="ActIdentitatePF" type="t:ActIdentitatePF" />
          <xsd:element name="Cnp">
            <xsd:simpleType>
              <xsd:restriction base="xsd:string">
                <xsd:maxLength value="256" />
              </xsd:restriction>
            </xsd:simpleType>
          </xsd:element>
          <xsd:element name="FormaJuridicaPF" type="t:FormaJuridicaPF" />
          <xsd:element name="FormaOrganizarePF" type="t:FormaOrganizarePF" minOccurs="0" nillable="true" />
          <xsd:element name="Nationalitate" type="t:Nationalitate" />
        </xsd:sequence>
      </xsd:extension>
    </xsd:complexContent>
  </xsd:complexType>
  <xsd:complexType name="DetaliiAngajatorPersoanaJuridica">
    <xsd:complexContent>
      <xsd:extension base="t:DetaliiAngajator">
        <xsd:sequence>
          <xsd:element name="Cui">
            <xsd:simpleType>
              <xsd:restriction base="xsd:string">
                <xsd:maxLength value="256" />
              </xsd:restriction>
            </xsd:simpleType>
          </xsd:element>
          <xsd:element name="CuiParinte" minOccurs="0" nillable="true">
            <xsd:simpleType>
              <xsd:restriction base="xsd:string">
                <xsd:maxLength value="256" />
              </xsd:restriction>
            </xsd:simpleType>
          </xsd:element>
          <xsd:element name="FormaJuridicaPJ" type="t:FormaJuridicaPJ" />
          <xsd:element name="FormaOrganizarePJ" type="t:FormaOrganizarePJ" minOccurs="0" nillable="true" />
          <xsd:element name="FormaProprietate" type="t:FormaProprietate" minOccurs="0" nillable="true" />
          <xsd:element name="NivelInfiintare" type="t:NivelInfiintare" minOccurs="0" nillable="true" />
          <xsd:element name="NumeParinte" minOccurs="0" nillable="true">
            <xsd:simpleType>
              <xsd:restriction base="xsd:string">
                <xsd:maxLength value="256" />
              </xsd:restriction>
            </xsd:simpleType>
          </xsd:element>
        </xsd:sequence>
      </xsd:extension>
    </xsd:complexContent>
  </xsd:complexType>
  <xsd:complexType name="DetaliiSalariatStrain">
    <xsd:complexContent>
      <xsd:extension base="t:AuditableEntity">
        <xsd:sequence>
          <xsd:element name="DataInceputAutorizatie" type="xsd:dateTime" />
          <xsd:element name="DataSfarsitAutorizatie" type="xsd:dateTime" minOccurs="0" nillable="true" />
          <xsd:element name="TipAutorizatie" type="t:TipAutorizatie" />
        </xsd:sequence>
      </xsd:extension>
    </xsd:complexContent>
  </xsd:complexType>
  <xsd:complexType name="DomeniuActivitate">
    <xsd:complexContent>
      <xsd:extension base="ns2:Entity">
        <xsd:sequence>
          <xsd:element name="Cod">
            <xsd:simpleType>
              <xsd:restriction base="xsd:string">
                <xsd:maxLength value="256" />
              </xsd:restriction>
            </xsd:simpleType>
          </xsd:element>
          <xsd:element name="Versiune" type="xsd:int" />
        </xsd:sequence>
      </xsd:extension>
    </xsd:complexContent>
  </xsd:complexType>
  <xsd:complexType name="Header">
    <xsd:complexContent>
      <xsd:restriction base="xsd:anyType">
        <xsd:sequence>
          <xsd:element name="ClientApplication" nillable="true">
            <xsd:simpleType>
              <xsd:restriction base="xsd:string">
                <xsd:maxLength value="256" />
              </xsd:restriction>
            </xsd:simpleType>
          </xsd:element>
          <xsd:element name="XmlVersion" type="xsd:int" />
          <xsd:element name="UploadId" type="ns1:guid" minOccurs="0" nillable="true" />
          <xsd:element name="UploadDescription" minOccurs="0" nillable="true">
            <xsd:simpleType>
              <xsd:restriction base="xsd:string">
                <xsd:maxLength value="256" />
              </xsd:restriction>
            </xsd:simpleType>
          </xsd:element>
          <xsd:element name="Angajator" type="t:Angajator" nillable="true" />
          <xsd:element name="PiecesCount" type="xsd:int" minOccurs="0" nillable="true" />
        </xsd:sequence>
      </xsd:restriction>
    </xsd:complexContent>
  </xsd:complexType>
  <xsd:complexType name="Localitate">
    <xsd:complexContent>
      <xsd:extension base="ns2:Entity">
        <xsd:sequence>
          <xsd:element name="CodSiruta" type="xsd:int" />
        </xsd:sequence>
      </xsd:extension>
    </xsd:complexContent>
  </xsd:complexType>
  <xsd:complexType name="Nationalitate">
    <xsd:complexContent>
      <xsd:extension base="ns2:Entity">
        <xsd:sequence>
          <xsd:element name="Nume">
            <xsd:simpleType>
              <xsd:restriction base="xsd:string">
                <xsd:maxLength value="256" />
              </xsd:restriction>
            </xsd:simpleType>
          </xsd:element>
        </xsd:sequence>
      </xsd:extension>
    </xsd:complexContent>
  </xsd:complexType>
  <xsd:complexType name="Salariat">
    <xsd:complexContent>
      <xsd:extension base="t:AuditableEntity">
        <xsd:sequence>
          <xsd:element name="Adresa">
            <xsd:simpleType>
              <xsd:restriction base="xsd:string">
                <xsd:maxLength value="256" />
              </xsd:restriction>
            </xsd:simpleType>
          </xsd:element>
          <xsd:element name="Cnp">
            <xsd:simpleType>
              <xsd:restriction base="xsd:string">
                <xsd:maxLength value="256" />
              </xsd:restriction>
            </xsd:simpleType>
          </xsd:element>
          <xsd:element name="CnpVechi" minOccurs="0" nillable="true">
            <xsd:simpleType>
              <xsd:restriction base="xsd:string">
                <xsd:maxLength value="256" />
              </xsd:restriction>
            </xsd:simpleType>
          </xsd:element>
          <xsd:element name="Contracte" type="t:ArrayOfContract" />
          <xsd:element name="DetaliiSalariatStrain" type="t:DetaliiSalariatStrain" minOccurs="0" nillable="true" />
          <xsd:element name="Localitate" type="t:Localitate" minOccurs="0" nillable="true" />
          <xsd:element name="Mentiuni" minOccurs="0" nillable="true">
            <xsd:simpleType>
              <xsd:restriction base="xsd:string">
                <xsd:maxLength value="256" />
              </xsd:restriction>
            </xsd:simpleType>
          </xsd:element>
          <xsd:element name="Nationalitate" type="t:Nationalitate" />
          <xsd:element name="Nume">
            <xsd:simpleType>
              <xsd:restriction base="xsd:string">
                <xsd:maxLength value="256" />
              </xsd:restriction>
            </xsd:simpleType>
          </xsd:element>
          <xsd:element name="Prenume">
            <xsd:simpleType>
              <xsd:restriction base="xsd:string">
                <xsd:maxLength value="256" />
              </xsd:restriction>
            </xsd:simpleType>
          </xsd:element>
          <xsd:element name="TipActIdentitate" type="t:TipActIdentitate" />
        </xsd:sequence>
      </xsd:extension>
    </xsd:complexContent>
  </xsd:complexType>
  <xsd:complexType name="Spor">
    <xsd:complexContent>
      <xsd:extension base="t:AuditableEntity">
        <xsd:sequence>
          <xsd:element name="IsProcent" type="xsd:boolean" minOccurs="0" />
          <xsd:element name="Tip" type="t:TipSpor" />
          <xsd:element name="Valoare" type="xsd:double" />
        </xsd:sequence>
      </xsd:extension>
    </xsd:complexContent>
  </xsd:complexType>
  <xsd:complexType name="TimpMunca">
    <xsd:complexContent>
      <xsd:restriction base="xsd:anyType">
        <xsd:sequence>
          <xsd:element name="Durata" type="xsd:double" minOccurs="0" nillable="true" />
          <xsd:element name="IntervalTimp" type="t:RepartizareIntervalTimp" minOccurs="0" nillable="true" />
          <xsd:element name="Norma" type="t:NormaTimpMunca" />
          <xsd:element name="Repartizare" type="t:RepartizareTimpMunca" />
        </xsd:sequence>
      </xsd:restriction>
    </xsd:complexContent>
  </xsd:complexType>
  <xsd:complexType name="TipSpor">
    <xsd:complexContent>
      <xsd:extension base="ns2:Entity">
        <xsd:sequence />
      </xsd:extension>
    </xsd:complexContent>
  </xsd:complexType>
  <xsd:complexType name="TipSporAngajator">
    <xsd:complexContent>
      <xsd:extension base="t:TipSpor">
        <xsd:sequence>
          <xsd:element name="Nume">
            <xsd:simpleType>
              <xsd:restriction base="xsd:string">
                <xsd:maxLength value="256" />
              </xsd:restriction>
            </xsd:simpleType>
          </xsd:element>
        </xsd:sequence>
      </xsd:extension>
    </xsd:complexContent>
  </xsd:complexType>
  <xsd:complexType name="TipSporPredefinit">
    <xsd:complexContent>
      <xsd:extension base="t:TipSpor">
        <xsd:sequence>
          <xsd:element name="Nume">
            <xsd:simpleType>
              <xsd:restriction base="xsd:string">
                <xsd:maxLength value="256" />
              </xsd:restriction>
            </xsd:simpleType>
          </xsd:element>
          <xsd:element name="Versiune" type="xsd:int" />
        </xsd:sequence>
      </xsd:extension>
    </xsd:complexContent>
  </xsd:complexType>
  <xsd:complexType name="XmlReport">
    <xsd:complexContent>
      <xsd:restriction base="xsd:anyType">
        <xsd:sequence>
          <xsd:element name="Header" type="t:Header" nillable="true" />
          <xsd:element name="Salariati" type="t:ArrayOfSalariat" />
        </xsd:sequence>
      </xsd:restriction>
    </xsd:complexContent>
  </xsd:complexType>
  <xsd:simpleType name="ActIdentitatePF">
    <xsd:restriction base="xsd:string">
      <xsd:enumeration value="Cnp" />
      <xsd:enumeration value="CnpCif" />
      <xsd:enumeration value="Pasaport" />
      <xsd:enumeration value="PasaportCif" />
      <xsd:enumeration value="PasaportActIdentitate" />
    </xsd:restriction>
  </xsd:simpleType>
  <xsd:simpleType name="ExceptieDataSfarsit">
    <xsd:restriction base="xsd:string">
      <xsd:enumeration value="Art83LitA" />
      <xsd:enumeration value="Art83LitE" />
      <xsd:enumeration value="Art83LitH" />
    </xsd:restriction>
  </xsd:simpleType>
  <xsd:simpleType name="FormaJuridicaPF">
    <xsd:restriction base="xsd:string">
      <xsd:enumeration value="PF" />
      <xsd:enumeration value="PFA" />
      <xsd:enumeration value="IF" />
      <xsd:enumeration value="ProfesieSpeciala" />
      <xsd:enumeration value="IPF" />
    </xsd:restriction>
  </xsd:simpleType>
  <xsd:simpleType name="FormaJuridicaPJ">
    <xsd:restriction base="xsd:string">
      <xsd:enumeration value="SocietateComerciala" />
      <xsd:enumeration value="RegieAutonoma" />
      <xsd:enumeration value="CompanieNationala" />
      <xsd:enumeration value="SocietateNationala" />
      <xsd:enumeration value="AutoritateInstitutiePublica" />
      <xsd:enumeration value="InstitutieDeCredit" />
      <xsd:enumeration value="SocietateCooperativa" />
      <xsd:enumeration value="OrganizatieSindicala" />
      <xsd:enumeration value="Fundatie" />
      <xsd:enumeration value="AltePersoaneJuridice" />
      <xsd:enumeration value="OrganizatiePatronala" />
      <xsd:enumeration value="OrganizatieAsociatieCuPersonalitateJuridica" />
      <xsd:enumeration value="ReprezentantaDinRomaniaPentruPJStraina" />
      <xsd:enumeration value="InstitutCulturalAlUnuiStat" />
      <xsd:enumeration value="ReprezentantaComercialaSiEconomicaAleAltuiStat" />
      <xsd:enumeration value="MisiuneDiplomatica" />
      <xsd:enumeration value="OficiuConsular" />
    </xsd:restriction>
  </xsd:simpleType>
  <xsd:simpleType name="FormaOrganizarePF">
    <xsd:restriction base="xsd:string">
      <xsd:enumeration value="Arhitect" />
      <xsd:enumeration value="AsistentMedical" />
      <xsd:enumeration value="AuditorFinanciar" />
      <xsd:enumeration value="Avocat" />
      <xsd:enumeration value="ConsilierProprietateIndustriala" />
      <xsd:enumeration value="ConsultantFiscal" />
      <xsd:enumeration value="ExecutorJudecatoresc" />
      <xsd:enumeration value="ExpertContabil" />
      <xsd:enumeration value="ExpertVamal" />
      <xsd:enumeration value="Farmacist" />
      <xsd:enumeration value="Medic" />
      <xsd:enumeration value="MedicVeterinar" />
      <xsd:enumeration value="NotarPublic" />
      <xsd:enumeration value="Psiholog" />
      <xsd:enumeration value="TraducatorAutorizat" />
      <xsd:enumeration value="LichidatorJudiciar" />
      <xsd:enumeration value="AltePersoaneFizice" />
    </xsd:restriction>
  </xsd:simpleType>
  <xsd:simpleType name="FormaOrganizarePJ">
    <xsd:restriction base="xsd:string">
      <xsd:enumeration value="Agricola" />
      <xsd:enumeration value="AlteInstitutiiDeCredit" />
      <xsd:enumeration value="AlteOrganizatiiPatronale" />
      <xsd:enumeration value="AlteOrganizatiiSauAsociatiiCuPersonalitateJuridica" />
      <xsd:enumeration value="AsociatieDeProprietari" />
      <xsd:enumeration value="Banca" />
      <xsd:enumeration value="CaseDeEconomiiPentruDomeniulLocativ" />
      <xsd:enumeration value="ConfederatieSindicala" />
      <xsd:enumeration value="DeConsum" />
      <xsd:enumeration value="DeLocuinte" />
      <xsd:enumeration value="DeTransporturi" />
      <xsd:enumeration value="DeValorificare" />
      <xsd:enumeration value="Federatiepatronala" />
      <xsd:enumeration value="Federatiesindicala" />
      <xsd:enumeration value="Forestiere" />
      <xsd:enumeration value="InstitutiiEmitenteDeMonedaElectronica" />
      <xsd:enumeration value="Mestesugareasca" />
      <xsd:enumeration value="OrganizatieCooperatistaDeCredit" />
      <xsd:enumeration value="OrganizatieSauAsociatieProfesionala" />
      <xsd:enumeration value="Patronat" />
      <xsd:enumeration value="Pescaresti" />
      <xsd:enumeration value="Sindicat" />
      <xsd:enumeration value="SocietateCuRaspundereLimitata" />
      <xsd:enumeration value="SocietateCuRaspundereLimitataDebutant" />
      <xsd:enumeration value="SocietateInComanditaPeActiuni" />
      <xsd:enumeration value="SocietateInComanditaSimpla" />
      <xsd:enumeration value="SocietateInNumeColectiv" />
      <xsd:enumeration value="SocietatePeActiuni" />
      <xsd:enumeration value="Sucursalaauneiinstitutiidecreditstraina" />
      <xsd:enumeration value="UniunePatronala" />
      <xsd:enumeration value="UniuneSindicala" />
    </xsd:restriction>
  </xsd:simpleType>
  <xsd:simpleType name="FormaProprietate">
    <xsd:restriction base="xsd:string">
      <xsd:enumeration value="Stat" />
      <xsd:enumeration value="Privata" />
      <xsd:enumeration value="Mixta" />
    </xsd:restriction>
  </xsd:simpleType>
  <xsd:simpleType name="NivelInfiintare">
    <xsd:restriction base="xsd:string">
      <xsd:enumeration value="SediuSocial" />
      <xsd:enumeration value="Filiala" />
      <xsd:enumeration value="Sucursala" />
    </xsd:restriction>
  </xsd:simpleType>
  <xsd:simpleType name="NormaTimpMunca">
    <xsd:restriction base="xsd:string">
      <xsd:enumeration value="NormaIntreaga840" />
      <xsd:enumeration value="NormaIntreaga630" />
      <xsd:enumeration value="NormaIntreagaLegiSpeciale" />
      <xsd:enumeration value="TimpPartial" />
    </xsd:restriction>
  </xsd:simpleType>
  <xsd:simpleType name="RepartizareIntervalTimp">
    <xsd:restriction base="xsd:string">
      <xsd:enumeration value="OrePeZi" />
      <xsd:enumeration value="OrePeSaptamana" />
      <xsd:enumeration value="OrePeLuna" />
    </xsd:restriction>
  </xsd:simpleType>
  <xsd:simpleType name="RepartizareTimpMunca">
    <xsd:restriction base="xsd:string">
      <xsd:enumeration value="OreDeZi" />
      <xsd:enumeration value="OreDeNoapte" />
      <xsd:enumeration value="Inegal" />
    </xsd:restriction>
  </xsd:simpleType>
  <xsd:simpleType name="TemeiIncetare">
    <xsd:restriction base="xsd:string">
      <xsd:enumeration value="Art55LitB" />
      <xsd:enumeration value="Art56Alin1LitA" />
      <xsd:enumeration value="Art56Alin1LitB" />
      <xsd:enumeration value="Art56Alin1LitC" />
      <xsd:enumeration value="Art56Alin1LitD" />
      <xsd:enumeration value="Art56Alin1LitE" />
      <xsd:enumeration value="Art56Alin1LitF" />
      <xsd:enumeration value="Art56Alin1LitG" />
      <xsd:enumeration value="Art56Alin1LitH" />
      <xsd:enumeration value="Art56Alin1LitI" />
      <xsd:enumeration value="Art56Alin1LitJ" />
      <xsd:enumeration value="Art61LitA" />
      <xsd:enumeration value="Art61LitB" />
      <xsd:enumeration value="Art61LitC" />
      <xsd:enumeration value="Art61LitD" />
      <xsd:enumeration value="Art65Alin1" />
      <xsd:enumeration value="Art68" />
      <xsd:enumeration value="Art81Alin1" />
      <xsd:enumeration value="Art81Alin7" />
      <xsd:enumeration value="Art81Alin8" />
      <xsd:enumeration value="Art31Alin3" />
      <xsd:enumeration value="HJ" />
      <xsd:enumeration value="NulitateContract" />
      <xsd:enumeration value="AltTemei" />
      <xsd:enumeration value="Art50LitH" />
    </xsd:restriction>
  </xsd:simpleType>
  <xsd:simpleType name="TemeiReactivare">
    <xsd:restriction base="xsd:string">
      <xsd:enumeration value="Reintegrare" />
    </xsd:restriction>
  </xsd:simpleType>
  <xsd:simpleType name="TemeiSuspendare">
    <xsd:restriction base="xsd:string">
      <xsd:enumeration value="Art54" />
      <xsd:enumeration value="Art50LiteraD" />
      <xsd:enumeration value="Art50LiteraE" />
      <xsd:enumeration value="Art50LiteraF" />
      <xsd:enumeration value="Art50LiteraG" />
      <xsd:enumeration value="Art50LiteraH" />
      <xsd:enumeration value="Art50LiteraI" />
      <xsd:enumeration value="Art51Alin1LiteraA" />
      <xsd:enumeration value="Art51Alin1LiteraB" />
      <xsd:enumeration value="Art51Alin1LiteraC" />
      <xsd:enumeration value="Art51Alin1LiteraD" />
      <xsd:enumeration value="Art51Alin1LiteraE" />
      <xsd:enumeration value="Art51Alin1LiteraF" />
      <xsd:enumeration value="Art51Alin2" />
      <xsd:enumeration value="Art52Alin1LiteraA" />
      <xsd:enumeration value="Art52Alin1LiteraB" />
      <xsd:enumeration value="Art52Alin1LiteraC" />
      <xsd:enumeration value="Art52Alin1LiteraD" />
      <xsd:enumeration value="Art52Alin1LiteraE" />
      <xsd:enumeration value="Art52Alin3" />
    </xsd:restriction>
  </xsd:simpleType>
  <xsd:simpleType name="TipActIdentitate">
    <xsd:restriction base="xsd:string">
      <xsd:enumeration value="CarteIdentitate" />
      <xsd:enumeration value="Pasaport" />
      <xsd:enumeration value="BuletinIdentitate" />
      <xsd:enumeration value="Alt" />
      <xsd:enumeration value="CarteDeRezidenta" />
      <xsd:enumeration value="PermisDeSedere" />
    </xsd:restriction>
  </xsd:simpleType>
  <xsd:simpleType name="TipAutorizatie">
    <xsd:restriction base="xsd:string">
      <xsd:enumeration value="LucratoriPermanenti" />
      <xsd:enumeration value="Exceptie" />
      <xsd:enumeration value="LucratoriSezonieri" />
      <xsd:enumeration value="LucratoriStagiari" />
      <xsd:enumeration value="Sportivi" />
      <xsd:enumeration value="Nominala" />
      <xsd:enumeration value="LucratoriTransfrontalieri" />
      <xsd:enumeration value="LucratorInaltCalificat" />
    </xsd:restriction>
  </xsd:simpleType>
  <xsd:simpleType name="TipContract">
    <xsd:restriction base="xsd:string">
      <xsd:enumeration value="ContractIndividualMunca" />
      <xsd:enumeration value="ContractUcenicie" />
      <xsd:enumeration value="ContractMuncaLaDomiciliu" />
      <xsd:enumeration value="ContractMuncaTemporara" />
    </xsd:restriction>
  </xsd:simpleType>
  <xsd:simpleType name="TipDurata">
    <xsd:restriction base="xsd:string">
      <xsd:enumeration value="Nedeterminata" />
      <xsd:enumeration value="Determinata" />
    </xsd:restriction>
  </xsd:simpleType>
  <xsd:simpleType name="TipNorma">
    <xsd:restriction base="xsd:string">
      <xsd:enumeration value="NormaIntreaga" />
      <xsd:enumeration value="TimpPartial" />
    </xsd:restriction>
  </xsd:simpleType>
</xsd:schema>';

