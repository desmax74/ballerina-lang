/*
 *  Copyright (c) 2016, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 *  WSO2 Inc. licenses this file to you under the Apache License,
 *  Version 2.0 (the "License"); you may not use this file except
 *  in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing,
 *  software distributed under the License is distributed on an
 *  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 *  KIND, either express or implied.  See the License for the
 *  specific language governing permissions and limitations
 *  under the License.
 */
package org.ballerinalang.model.values;

import org.ballerinalang.model.types.BType;
import org.ballerinalang.model.types.BTypes;
import org.ballerinalang.util.exceptions.BallerinaErrorReasons;
import org.ballerinalang.util.exceptions.BallerinaException;

import java.math.BigDecimal;
import java.math.MathContext;
import java.util.Map;

import static org.ballerinalang.bre.bvm.BVM.isByteLiteral;

/**
 * The {@code BInteger} represents a int value in Ballerina.
 *
 * @since 0.8.0
 */
public final class BInteger extends BValueType implements BRefType<Long> {

    private long value;
    private BType type = BTypes.typeInt;

    public BInteger(long value) {
        this.value = value;
    }

    @Override
    public long intValue() {
        return this.value;
    }

    @Override
    public byte byteValue() {
        if (!isByteLiteral(this.value)) {
            throw new BallerinaException(BallerinaErrorReasons.NUMBER_CONVERSION_ERROR,
                                         "'int' value '" + value + "' cannot be converted to 'byte'");
        }
        return (byte) this.value;
    }

    @Override
    public double floatValue() {
        return (double) this.value;
    }

    @Override
    public BigDecimal decimalValue() {
        return new BigDecimal(stringValue(), MathContext.DECIMAL128).setScale(1, BigDecimal.ROUND_HALF_EVEN);
    }

    @Override
    public boolean booleanValue() {
        return value != 0;
    }

    @Override
    public String stringValue() {
        return Long.toString(value);
    }

    @Override
    public BType getType() {
        return type;
    }

    @Override
    public void setType(BType type) {
        this.type = type;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) {
            return true;
        }
        if (o == null || getClass() != o.getClass()) {
            return false;
        }

        BInteger bInteger = (BInteger) o;

        return value == bInteger.value;

    }

    @Override
    public int hashCode() {
        return (int) (value ^ (value >>> 32));
    }

    @Override
    public Long value() {
        return value;
    }

    @Override
    public BValue copy(Map<BValue, BValue> refs) {
        return this;
    }
}
