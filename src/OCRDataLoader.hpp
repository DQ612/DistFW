// Author: Veeru Sadhanala (vsadhana@cs.cmu.edu)
// Date: 2014.05.24

#pragma once

#include <iostream>
#include "common.hpp"
#include <vector>
#include <string>

namespace fw {

class OCRDataLoader {
public:
    OCRDataLoader(){}

    // load X, y
    // X : vector(n,vector(128m_i))
    // y : vector(n,vector<m_i>)

    typedef std::vector<double> Covariate;
    typedef std::shared_ptr<Covariate> CovariatePtr;
    typedef std::vector< CovariatePtr > Covariates;
    typedef std::shared_ptr< Covariates > CovariatesPtr;

    typedef std::vector< int > Label;
    typedef std::shared_ptr< Label > LabelPtr;
    typedef std::vector< LabelPtr > Labels;
    typedef std::shared_ptr< Labels > LabelsPtr;

    typedef std::pair< CovariatesPtr, LabelsPtr> Dataset;

    Dataset load( const std::string& dataName, 
            const std::string& dataPath );

};

}
